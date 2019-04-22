#!/bin/bash

register () {
	flag=0
	while [ $flag -eq 0 ]
	do
		echo "Enter username to register"
		read username
		valid=($(echo $(grep $username touristDatabase.txt) | tr ' ' '\n'))
		if [ ${#valid[@]} -eq 0 ]; then
			files=$(ls)
			arrayFiles=($(echo $files | tr '\n' '\n'))
			checkFor="touristDatabase.txt"
			fileFlag=0
			for i in ${!arrayFiles[*]}
			do
				if [ "$checkFor" == "${arrayFiles[$i]}" ]; then
					fileFlag=1							
					break
				fi
			done
			if [ $fileFlag -eq 0 ]; then
				fileName=$checkFor
				touch $fileName
				echo "Name" > $fileName
			fi
			newLine1=$username
			echo $newLine1 >> touristDatabase.txt
			break
		else
			printf "Invalid username(already taken)...\n"
			break		
		fi
	done
}


scrapeFromDataBase () {
	printf "\nAccomodation prices of all rooms hotel wise\n"
	printf "+++++++++++++++++++++++++++++++++++++++++++++++\n(columns)"
	while read line; do echo $line; done < roomDatabase.txt
	printf "\n+++++++++++++++++++++++++++++++++++++++++++++++\n"
}




roomTypesAndRates () {
	echo "Total record of all rooms hotel wise(non expanded view) : "
	printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
	printf "(columns)"
	while read line; do echo $line; done < hotelDatabase.txt
	printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
	printf "\n Do you wish to view individual room records :(0/1)"
	read choice
	
	if [ $choice -eq 1 ]; then
		printf "++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
		printf "Available Rooms(expanded view):\n(columns)HotelName RoomType RoomRate RoomNo"
		printf "\n=========================================================\n"
		while read line
		do	
			IFS=$'\n'
			array=($(echo $line | tr ' ' '\n'))
			for index in ${!array[*]}
			do
				if [ "${array[$index]: 0:1}" == "0" ]; then
					echo "${array[@]:1:4}"
				fi
			done
		done < roomDatabase.txt
	fi
	printf "++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
	IFS=$' \t\n'
}

bookRoom () {
	echo "Enter your tourist id : "
	read touristId
	flagTouristExists=0
	var=$(grep $touristId touristDatabase.txt)
	array=($(echo $var | tr ' ' '\n'))
	if [ "${#array[@]}" -gt 0 ]; then
		flagTouristExists=1
	fi
	
	if [ "$flagTouristExists" -eq 0 ]; then
		echo "You are not a registered tourist...wanna reg now(0/1) ?:"
		read temp
		if [ "$temp" -eq 1 ]; then
			register
		else
			return
		fi
	fi
	
	echo "Available choices : "
	roomTypesAndRates
	newLine=0
	rightOption=0
	while [ "$rightOption" -eq 0 ]; do
		echo "Enter valid hotelName(space)RoomNo"
		read hotelName roomNo
		while read line     #for updating roomDatabase.txt
		do
			array=($(echo $line | tr ' ' '\n'))
			if [ "${array[1]}" == "$hotelName" -a "${array[4]}" == "$roomNo" ]; then
				if [[ "${array[5]}" = *0* ]]; then
					rightOption=1
					newLine="${array[0]} ${array[1]} ${array[2]} ${array[3]} ${array[4]} 1"
					oldLine="${array[0]} ${array[1]} ${array[2]} ${array[3]} ${array[4]} 0"
					sed -i "s/$oldLine/$newLine/g" roomDatabase.txt
					
					while read line1  #for updating hotelDatabase.txt
					do
						array1=($(echo $line1 | tr ' ' '\n'))
						if [ "${array1[1]}" == "$hotelName" ]; then
							if [ "${array[2]}" == "delux" ];then
								oldLine="${array1[0]} ${array1[1]} ${array1[2]} ${array1[3]} ${array1[4]} ${array1[5]}"	
								tempArray=$(echo "${array1[3]} - 1" | tr -d $'\r' | bc)
								newLine="${array1[0]} ${array1[1]} ${array1[2]} $tempArray ${array1[4]} ${array1[5]}"
								sed -i "s/$oldLine/$newLine/g" hotelDatabase.txt
							else
								oldLine="${array1[0]} ${array1[1]} ${array1[2]} ${array1[3]} ${array1[4]} ${array1[5]}"
								tempArray=$(echo "${array1[5]} - 1" | tr -d $'\r' | bc)
								newLine="${array1[0]} ${array1[1]} ${array1[2]} ${array1[3]} ${array1[4]} $tempArray"
								sed -i "s/$oldLine/$newLine/g" hotelDatabase.txt
	
							fi
						fi
					done < hotelDatabase.txt
						
					files=$(ls)
					arrayFiles=($(echo $files | tr '\n' '\n'))
					temp='bookings.txt'
					checkFor=$hotelName$temp
					fileFlag=0					
					for i in ${!arrayFiles[*]}
					do
						if [ "$checkFor" == "${arrayFiles[$i]}" ]; then
							fileFlag=1							
							break
						fi
					done
					if [ $fileFlag -eq 0 ]; then
						fileName=$checkFor
						touch $fileName
						echo "Slno Name Roomno" > $fileName
					fi
					IFS=$'\n'
					arrayFileContents=($(cat $checkFor | tr '\n' '\n'))
					IFS=$' \t\n'
					lastIndex=${#arrayFileContents[@]}
					newLine1=$lastIndex" "$touristId" "${array[4]}
					echo $newLine1 >> $checkFor     #for updation of respective booking files for a selected hotel
					rightOption=1					
					break				
				fi
			fi
		done < roomDatabase.txt
		if [ $rightOption -eq 0 ]; then
			printf "Invalid option ...\n"
			return
		fi
	done
}

packageDetails () {
	echo "Enter hotelName roomType(0/1)(normal/delux) days"
	read hotelName roomType days
	flagHotelExists=0
	varHotel=$(grep $hotelName hotelRates.txt)
	arrayHotels=($(echo $varHotel | tr ' ' '\n'))
	if [ ${#arrayHotels[@]} -eq 0 ]; then
		printf "No such hotel in list \n"
		return
	fi
	
	hotelType=(normal delux)
	while read line
	do
		record=($(echo $line | tr ' ' '\n'))
		if [ "${record[0]}" == "$hotelName" -a "${record[1]}" == "$roomType" ]; then
			output=$(echo "${record[2]} * $days" | tr -d $'\r' | bc)
			echo "Package for "${record[0]}" hotel for "${hotelType[${record[$roomType]}]}" type room for "$days" days is "$output
		fi
	done < hotelRates.txt
}

registerHotel () {
	echo "Present hotels :"
	scrapeFromDataBase
	echo "Enter hotelName to register your hotel(unique)"
	read hotelName
	varHotel_=$(grep $hotelName hotelRates.txt)
	arrayHotels_=($(echo $varHotel_ | tr ' ' '\n'))
	totalDeluxRooms=0
	deluxRoomsAvailable=0
	totalNormalRooms=0
	normalRoomsAvailable=0
	if [ ${#arrayHotels_[@]} -gt 0 ]; then
		echo "Hotel already registered..."
	else
		echo "Enter your normal and delux rates : "
		read normal delux
		roomRates=($normal $delux)
		roomTypes=(normal delux)
		echo "Enter no of rooms : "
		read rooms
		IFS=$'\n'
		arrayFileContents=($(cat roomDatabase.txt | tr '\n' '\n'))
		IFS=$' \t\n'
		lastIndex=${#arrayFileContents[@]}
		for i in `seq 1 $rooms`
		do
			echo "Room "$i" is (0/1)(normal/delux)?:"
			read type_
			if [ $type_ -eq 1 ]; then
				totalDeluxRooms=`expr $totalDeluxRooms + 1`
				deluxRoomsAvailable=`expr $deluxRoomsAvailable + 1`
			else
				totalNormalRooms=`expr $totalNormalRooms + 1`
				normalRoomsAvailable=`expr $normalRoomsAvailable + 1`
			fi
			newLine=$lastIndex" "$hotelName" "${roomTypes[$type_]}" "${roomRates[$type_]}" "$i" 0"
			echo $newLine >> roomDatabase.txt
			lastIndex=`expr $lastIndex + 1`
		done
		newLine=$hotelName" 1 "${roomRates[1]}
		echo $newLine >> hotelRates.txt
		newLine=$hotelName" 0 "${roomRates[0]}
		echo $newLine >> hotelRates.txt
		IFS=$'\n'
		arrayFileContents=($(cat hotelDatabase.txt | tr '\n' '\n'))
		IFS=$' \t\n'
		lastIndex=${#arrayFileContents[@]}
		newLine=$lastIndex" "$hotelName" "$totalDeluxRooms" "$deluxRoomsAvailable" "$totalNormalRooms" "$normalRoomsAvailable
		echo $newLine >> hotelDatabase.txt
	fi
}

while((1))
do
	printf "Options\n"
	printf "1) View the accomodation price.\n"
	printf "2) View room types and rates.\n"
	printf "3) Select rooms.\n"
	printf "4) View packege details.\n"
	printf "5) Register your hotel.\n"
	printf "6) Exit.\n"
	read option
	if [ $option -eq 6 ]; then
		break

	elif [ $option -eq 2 ]; then
		roomTypesAndRates
	elif [ $option -eq 1 ]; then
		scrapeFromDataBase
	elif [ $option -eq 3 ]; then
		bookRoom
	elif [ $option -eq 4 ]; then
		packageDetails
	elif [ $option -eq 5 ]; then
		registerHotel
	fi
done

#!/bin/bash
# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
# LIABILITY.
# 
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************
#

#Functions to print admin results

function calcLineWidth() {
	columnNum=$1
	columnPrintWidth=$2
	maxVmNameLen=$3
	index=0
	declare -i lineWidth
	lineWidth=0
	while ((index<columnNum));do
		if [ $index -eq 0 ];then
			lineWidth+=$maxVmNameLen
		elif [ ${#resultArr[$index]} -gt $columnPrintWidth ];then
			lineWidth+=${#resultArr[$index]}
		else
			lineWidth+=$columnPrintWidth
		fi
		((index++))
	done
	lineWidth+=$((columnNum+1))
	echo $lineWidth
}

function printLine() {
	length=$1;
	echo
	for ((i=0;i<$length;i++));do
		printf "%c" '-'
	done
	echo
}

function printContent() {
	columnNum=$1
	columnPrintWidth=$2

	if [ $columnNum -eq 0 ];then
		return 1
	fi
	#Calc max vm name length
	maxVmNameLen=0
	declare -i index
	index=0
	while ((index<${#resultArr[@]}));do
		if [ $((index%columnNum)) -eq 0 -a ${#resultArr[$index]} -gt $maxVmNameLen ];then
			maxVmNameLen=${#resultArr[$index]}
		fi
		index+=$columnNum
	done

	#Calc line width
	lineWidth=`calcLineWidth $columnNum $columnPrintWidth $maxVmNameLen`

	#Print results
	index=0
	while ((index<${#resultArr[@]}));do
		if [ $((index%columnNum)) -eq 0 ];then
			#printLine $((columnNum*columnPrintWidth+1))
			printLine $lineWidth
			printf "|"
		fi
		if [[ -n "${resultArr[$index]}" && ${resultArr[$index]} = 0 ]];then
			columnContent="PASS"
		elif [[ ${resultArr[$index]} =~ ^[0-9]+$ ]];then
			columnContent="FAIL"
		else
			columnContent=${resultArr[$index]}
		fi

		if [ $((index%columnNum)) -eq 0 ];then
		    printWidth=$((maxVmNameLen+1))
		elif [ $index -gt $columnNum -a $((index%columnNum)) -gt 0 -a ${#resultArr[$((index%columnNum))]} -gt $columnPrintWidth ];then
			printWidth=$((${#resultArr[$((index % columnNum))]}+1))
		else
			printWidth=$((columnPrintWidth+1))
		fi
		printf "%${printWidth}s" "${columnContent}""|"
		((index++))
	done
	printLine $lineWidth

}

function generateAdminArrFromLog() {
	logFile=$1
	lineNum=`sed -n '/Administration result table is:/,$p' $logFile | sed '/Administration result table is/d' | sed '/^-*$/d'|wc -l`
	content=`sed -n '/Administration result table is:/,$p' $logFile | sed '/Administration result table is/d' | sed '/^-*$/d'`
	OIFS=$IFS
	IFS="|"
	contentArr=(${content})
	if [ $lineNum -eq 0 ];then
		return 1
	fi
	columnNum=$((${#contentArr[@]}/lineNum))
	
	i=0
	unset resultArr
	for ((index=0;index<${#contentArr[@]};index++));do
		if [ $((index%columnNum)) -eq 0 ];then 
			continue
		fi
		resultArr[$i]=${contentArr[$index]}
		((i++))
	done
	((columnNum--))
	IFS=$OIFS
	unset contentArr
}

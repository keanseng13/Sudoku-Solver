#!/bin/bash
USERINPUT="/tmp/userinput"
USERINPUT2="/tmp/userinput2"
RESULT="/tmp/result"
RESULTBAK="/tmp/resultbak"
RESTEMP="/tmp/restemp"
OUTPUT="/tmp/output"

touch $USERINPUT
touch $USERINPUT2
touch $RESULT
touch $RESTEMP
touch $OUTPUT

> $USERINPUT
> $USERINPUT2
> $RESULT

STARTTIME=`date`

get_input () {
        echo -n "Enter 9 rows digits with each digit between 1 and 9 or - for n/a"
        echo ""

        i=1
        while [ $i -lt 10 ]
        do
                echo -ne "Row[${i}] : "
                read row
                echo -ne "$row\n" >> $USERINPUT
                let i=i+1
        done

        cat $USERINPUT  | tr -d " \t\r" > $USERINPUT2
}
get_input


set_BCR () {
        blk=$1
        col=$2
        row=$3

        let rfin=row+2
        let cfin=col+2
        x=1

        for i in `cat $USERINPUT2`
        do
                if [[ $row -eq $x && $row -le $rfin ]] ; then
                        while [ $col -le $cfin ]
                        do
                                val=`echo $i | cut -c${col}`
                                echo "$blk:C$col:R$row:$val" >> $RESULT
                                let col=col+1
                        done
                        let col=col-3
                let row=row+1
                fi
        let x=x+1
        done
}


set_BCR1 () {
        set_BCR B1 1 1
        set_BCR B2 1 4
        set_BCR B3 1 7
        set_BCR B4 4 1
        set_BCR B5 4 4
        set_BCR B6 4 7
        set_BCR B7 7 1
        set_BCR B8 7 4
        set_BCR B9 7 7
}
set_BCR1


set_restemp () {
        cat $RESULT | grep - | cut -d'-' -f1 > $RESTEMP

        typeset a=1
        while [ $a -le 9 ] ; do
        tmpval="-1-2-3-4-5-6-7-8-9"

                for val1 in `cat $RESULT | grep B${a} | grep -v - | cut -d':' -f4 | sort`
                do
                        tmpval=`echo "$tmpval" | sed "s/-$val1//"`
                done

                for val1 in `cat $RESTEMP | grep B${a}`
                do
                        sed -i "s/$val1/&$tmpval/" $RESTEMP
                done

        let a=a+1
        done
}



remove_posi () {
        line=`sed -n "/$1/ =" $RESTEMP`
        sed -i "${line}s/$2//" $RESTEMP
}



update_result () {
        rowchk=`echo "$1" | cut -d':' -f2`
        colchk=`echo "$1" | cut -d':' -f3`

        uni1=`cat $RESULT | grep "$rowchk" | grep -w "$2" | wc -l`
        uni2=`cat $RESULT | grep "$colchk" | grep -w "$2" | wc -l`

        if [[ $uni1 -eq 0 && $uni2 -eq 0 ]] ; then
                line=`sed -n "/$1/ =" $RESULT`
                sed -i "${line}s/-/$2/" $RESULT
                echo "UPDATE result $1 value: $2"
        fi
}



col_check () {
        typeset a=1
        while [ $a -le 9 ] ; do
                for val1 in `cat $RESULT | grep C${a} | grep -v - | cut -d':' -f4 | sort`

                do
                        for val2 in `cat $RESTEMP | grep C${a} | cut -d'-' -f1`
                        do
                                remove_posi $val2 "-$val1"
                        done
                done

                for val1 in `cat $RESULT | grep R${a} | grep -v - | cut -d':' -f4 | sort`
                do
                        for val2 in `cat $RESTEMP | grep R${a} | cut -d'-' -f1`
                        do
                                remove_posi $val2 "-$val1"
                        done
                done

        let a=a+1
        done
}



uniq_c () {
        uni=`cat $RESTEMP | grep "$1""$2"  | grep -w "$3" | wc -l`
        if [ $uni -eq 1 ] ; then
                val1=`cat $RESTEMP | grep $1$2  | grep -w $3 | cut -d'-' -f1`
                update_result $val1 $3
        fi

}

uniq_check () {
        typeset a=1
        while [ $a -le 9 ] ; do

                typeset b=1
                while [ $b -le 9 ] ; do

                        uniq_c B $a $b
                        uniq_c C $a $b
                        uniq_c R $a $b

                let b=b+1
                done

        let a=a+1
        done
}



run_5 () {
round=1
while true
do
        echo "+++++++++++++++++ ROUND $round +++++++++++++++++"
        set_restemp
        col_check
        uniq_check

        for i in `cat $RESTEMP`
        do
                val=`echo $i | wc -c`

                if [ $val -eq 12 ] ; then
                        num=`echo $i | cut -d'-' -f2`
                        bcr=`echo $i | cut -d'-' -f1`
                        update_result $bcr $num
                fi
        done


        let second=first
        first=`cat $RESULT | grep - | wc -l`
        echo "Second Value $second"
        echo "First Value $first"

        if [ $first -eq $second ] ; then
                break
        fi
let round=round+1
done
}
run_5

cp $RESULT $RESULTBAK
echo "******* BACKUP RESULT *******"

random_guess () {
        while [[ `cat $RESULT | grep - | wc -l` -gt 0 ]] ; do

                for i in `cat $RESTEMP`
                do
                        val=`echo $i | wc -c`

                        if [ $val -eq 10 ] ; then
                                cp $RESULTBAK $RESULT
                                echo "******* RESTORE RESULT *******"
                                break
                        elif [ $val -eq 12 ] ; then
                                num=`echo $i | cut -d'-' -f2`
                                bcr=`echo $i | cut -d'-' -f1`
                                update_result $bcr $num
                        fi
                done

                for i in `cat $RESTEMP`
                do
                        val=`echo $i | wc -c`
                        if [ $val -eq 14 ] ; then
                                randnum=`echo $((RANDOM%2+2))`
                                num=`echo $i | cut -d'-' -f$randnum`
                                bcr=`echo $i | cut -d'-' -f1`

                                echo "----- Guess value $i value is $num"
                                update_result $bcr $num
                                break
                        fi
                done
                run_5
        done
}
random_guess



i=1
while [ $i -le 9 ]
do
        x=1
        for val in `cat $RESULT | grep C$i | cut -d':' -f4`
        do
                if [ $i -eq 1 ] ; then
                        echo $val >> $OUTPUT
                else
                        sed -i "${x}s/$/$val/" $OUTPUT
                        let x=x+1
                fi
        done
        let x=x-9
let i=i+1
done

echo -e "\n"
echo "Start Time"
echo $STARTTIME
echo "End Time"
date
echo -e "\n"

cat $OUTPUT | sed 's/.\{3\}/& /g' | sed '7i\\' | sed '4i\\'

rm $USERINPUT
rm $USERINPUT2
rm $RESULT
rm $RESULTBAK
rm $RESTEMP
rm $OUTPUT

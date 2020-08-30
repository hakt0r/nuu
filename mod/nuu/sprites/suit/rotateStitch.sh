#!/bin/bash

infile="suit.png"
incr=10
inname=`convert "$infile" -format "%t" info:`

rm -rf out
mkdir out/


x=1
for ((i=90; i<=460; i=i+incr)); do
  convert "$infile" -background transparent -distort ScaleRotateTranslate $i +repage out/${inname}_$x.png
  ((x++));
done

sync

montage -tile 6x6 \
  out/${inname}_{1,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2}.png \
  -geometry 24x24+0+0 -background transparent \
  st_${inname}.png
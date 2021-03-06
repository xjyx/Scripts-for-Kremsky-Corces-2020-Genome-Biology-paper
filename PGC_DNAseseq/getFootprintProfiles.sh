#Note: must generate /media/4TB4/isaac/PGC_RNAseq/ids before running this code
mkdir fpProfiles
qval=1.1
i=1

for motif in $(cat /media/4TB4/isaac/PGC_RNAseq/ids)
do
	file=/media/4TB4/isaac/PGC_DNAseseq/bed/${motif}/E14.5_male_pooled.sorted.duprmvdatfimo_${motif}.distalHi.fpkm
	bamFile=bam/E14.5_male_pooled.sorted.duprmvd.bam
#	ctrlFile=$(ls pooled/Sperm*${other}*TFs*.bam)
	outFile=fpProfiles/$(basename $file | awk '{gsub(".fpkm", ".png"); print}')
	awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,"0",$6}' $file | sort -k1,1 -k2n,2 > ${motif}.forfpProfile.bed
	/programs/anaconda3/envs/py27/bin/dnase_average_profile.py ${motif}.forfpProfile.bed $bamFile $outFile &
#        /programs/anaconda3/envs/py27/bin/dnase_average_profile.py $file $ctrlFile $(echo $outFile | awk '{gsub(".png", "_ctrl.png"); print}') &
	if [ $(echo $i | awk '{print $1%15}') -eq 0 ]; then
		wait
	fi
	i=$(expr $i + 1)
done
wait

cd fpProfiles
rm *_withLabl*
for file in $(ls *.png | grep -v _withLabl)
do
        label=$(basename $file .png | cut -f4- -d"_" | awk '{sub(".distalHi", ""); print}')
	count=$(cat /media/4TB4/isaac/PGC_DNAseseq/bed/${label}/E14.5_male_pooled.sorted.duprmvdatfimo_${label}.distalHi.fpkm | wc -l)
        bedFile=$(basename $file .png).bed
        outFile=$(echo $file | awk '{gsub(".png", "_withLabl.png"); print}')
        convert -pointsize 36 -annotate +350+40 "$label (n=$count)" $file $outFile &
done
wait

montage -geometry 300x300 -tile 5x8 -density 300 $(ls *withLabl.png | grep -v ctrl) DNAseseq_FootprintProfiles.pdf &
#montage -geometry 300x300 -tile 5x8 $(ls *withLabl.png | grep ctrl) Sperm_Control_ATACseqFootprints_ctrl.pdf &
wait


motif=All
region=distal
compareStage=E14.5mPGCmeatE14.5mHi_HivLoAffinity
TF=All
fimo=/media/4TB4/isaac/PGC_DNAseseq/bed/${motif}/fimo_${motif}.forigv.bed
affinityFile=/media/4TB4/isaac/PGC_RNAseq/E16.5m_highestAffinities.bed
fpkmFile=/media/4TB4/isaac/PGC_DNAseseq/bed/All/E14.5_male_pooled.sorted.duprmvdatfimo_All.distalHi.fpkm
name1="TRAP Affinity >= 1"
name2="TRAP Affinity < 1"


awk '$NF >= 1' $affinityFile > HiAffinities.bed
awk '$NF < 1' $affinityFile > LoAffinities.bed
intersectBed -u -a $fpkmFile -b HiAffinities.bed > temp; mv temp HiAffinities.bed
intersectBed -u -a $fpkmFile -b LoAffinities.bed > temp; mv temp LoAffinities.bed

motifFile=HiAffinities.bed
ctrlFile=LoAffinities.bed



onePosSample () {
        yLabel="% meCpG/CpG"
        name_1="ATAC-Seq peaks"
        name_2="random peaks"
        outName="$type"
        dataLab="$type"
        RefLabel="peak center"
	altType=$(basename $bedFile | cut -f1 -d"_")

	echo $bedFile
	echo $M
	if [ -e ${type}_${motif}_${compareStage}_${region}.me ]; then 
        	echo file exists
        else
                intersectBed -u -a $bedFile -b $motifFile | awk 'BEGIN{OFS="\t"}{print $4,$5+$6}' > ${type}_${motif}_${compareStage}_${region}.me &
		intersectBed -u -a $bedFile -b $motifFile > ${type}_${motif}_${compareStage}_${region}.bed &
                intersectBed -u -a $bedFile -b $ctrlFile | awk 'BEGIN{OFS="\t"}{print $4,$5+$6}' > ${type}_${motif}_${compareStage}_${region}_ctrl.me &
		intersectBed -u -a $bedFile -b $ctrlFile >  ${type}_${motif}_${compareStage}_${region}_ctrl.bed &
		intersectBed -u -a $bedFile -b $motifFile | awk 'BEGIN{OFS="\t"}{print $1,$2,$3,$4,$5+$6}' > ${type}_${motif}_${compareStage}_${region}.me.bed &
	fi

	 if [ -e ${type}_all.me ]; then 
                echo ${type}_all.me exists
        else
		awk 'BEGIN{OFS="\t"}{print $4,$5+$6}' $bedFile > ${type}_all.me &
	fi
	wait
#	awk '$5+$6 > 5 && $4 > .25'  ${type}_${motif}_${compareStage}_${region}_ctrl.bed >  ${type}_${motif}_${compareStage}_${region}_ctrl.meHi.bed
#	awk '$5+$6 > 5 && $4 == 0'  ${type}_${motif}_${compareStage}_${region}_ctrl.bed >  ${type}_${motif}_${compareStage}_${region}_ctrl.meLo.bed
#	intersectBed -u -a $ctrlFile -b ${type}_${motif}_${compareStage}_${region}_ctrl.meHi.bed > temp; mv temp ${type}_${motif}_${compareStage}_${region}_ctrl.meHi.bed
#	intersectBed -u -a $ctrlFile -b ${type}_${motif}_${compareStage}_${region}_ctrl.meLo.bed > temp; mv temp ${type}_${motif}_${compareStage}_${region}_ctrl.meLo.bed
#	R --vanilla --args ${type}_${motif}_${compareStage}_${region}_ctrl.me ${type}_${motif}_${region}_ctrl ${compareStage} < getmeScatterPlot.R

	if [ $(grep $type avgme_${motif}_${compareStage}_${region}.txt | wc -l) -gt 0 ]; then
		echo avgme_${motif}.txt exists
	else
                R --vanilla --args ${type}_${motif}_${compareStage}_${region}.me ${type}_${motif}_${compareStage}_${region}_ctrl.me $type ${motif}_${compareStage}_${region} ${type}_all.me < getWeightedMeanandSD_disalPeaks.R
		echo .
	fi
}

strain=paternal
for strain in paternal
#maternal
do
	rm avgme.txt
	for bedFile in /Zulu/isaac/PGCme/bed/E9.5BS-Seq_meth.bed /Zulu/isaac/PGCme/bed/E10.5BS-Seq_meth.bed /Zulu/isaac/PGCme/bed/E11.5BS-Seq_meth.bed /Zulu/isaac/PGCme/bed/E13.5mBS-Seq_meth.bed /Zulu/isaac/PGCme/bed/E16.5mBS-Seq_meth.bed
	do
	        type=$(basename $bedFile | cut -f1 -d"_" | awk '{sub("BS-Seq", ""); print}')
	        echo $bedFile
	        echo $type
	        onePosSample
	done
	wait
	N_accessible=$(intersectBed -u -a $fimo -b $motifFile | wc -l)
	N_inaccessible=$(intersectBed -u -a $fimo -b $ctrlFile | wc -l)
	if [ $N_accessible -gt 0 ]; then
		if [ $(awk -v TF=$motif '$1 == TF' countTable_$compareStage | wc -l) -eq 0 ]; then
			echo $motif $N_accessible $N_inaccessible | awk '{gsub(" ", "\t"); print}' >> countTable_$compareStage
			echo .
		fi
	fi
	R --vanilla --args avgme_${motif}_${compareStage}_${region}.txt ${motif}_$region ${compareStage} $N_accessible $N_inaccessible "$name1" "$name2" < getLinePlot_distalPeaks.R
done
echo done

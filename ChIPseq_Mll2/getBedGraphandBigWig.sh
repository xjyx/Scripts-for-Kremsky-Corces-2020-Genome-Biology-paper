mkdir bed
process ()
{
	macs2 predictd -i $file 2> bam/$(basename $file .bam).fraglen.txt
	sl=$(grep "predicted fragment length is" bam/$(basename $file .bam).fraglen.txt | cut -f2 -d"#" | awk '{gsub("predicted fragment length is ", ""); gsub(" bps" , ""); print}' | awk '{print int($1/2)}')
	bamToBed -i $file | grep -v chrM | awk -v sl=$sl 'BEGIN{OFS="\t"}{if($6 == "+") print $1,$2+sl,$3+sl,$4,$5,$6; else print $1,$2-sl,$3-sl,$4,$5,$6}' > bed/$(basename $file .bam).bed
	wc -l bed/$(basename $file .bam).bed | awk '{sub("bed/", ""); print}' >> bed/readCounts
	M=$(awk -v x=$(basename $file .bam).bed 'BEGIN{count=0}{if($2 == x) count+=$1/1000000}END{print 1/count}' bed/readCounts)
	grep -v chrM bed/$(basename $file .bam).bed | cut -f1-3 | sort -k1,1 | bedtools genomecov -scale $M -i - -g /home/genomefiles/mouse/mm9_sizes.txt -bg >  bed/$(basename $file .bam).bedGraph
	bedGraphToBigWig bed/$(basename $file .bam).bedGraph /home/genomefiles/mouse/mm9_sizes.txt bed/$(basename $file .bam).bw
}

for file in $(ls bam/*distal.bam)
do
	process &
done
wait
echo done

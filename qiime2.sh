Date
cores=1
cd /home/evarela/Paper_final/
echo "Importe los datos de las secuencias a QIIME2"
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path se-33-manifest.tsv \
  --output-path single-end-demux.qza \
  --input-format SingleEndFastqManifestPhred33V2  
echo "Genere un archivo de visualización para examinar la calidad de las secuencias"
qiime demux summarize \
  --i-data single-end-demux.qza \
  --o-visualization single-demux-end.qzv
echo "Genere un archivo de visualización para examinar la calidad de las secuencias  denoise-single"
qiime dada2 denoise-single --i-demultiplexed-seqs single-end-demux.qza --p-trunc-len 253 --p-trim-left 0 --o-representative-sequences rep-seqs.qza --o-table table.qza --p-n-threads $cores --o-denoising-stats stats.qza
echo "Genere el stats-dada2.qzv"
qiime metadata tabulate \
  --m-input-file stats.qza \
  --o-visualization stats-dada2.qzv  
echo "Genere el FeatureTable y FeatureData summaries"
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample-metadata_modified.tsv 
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv
echo "Filtre el feature table (Total-frequency-based filtering"
qiime feature-table filter-samples \
  --i-table table.qza \
  --p-min-frequency 6000 \
  --o-filtered-table /home/evarela/Paper_final/filtered-sequences/filtered-table.qza
echo "Filtre características (features) con muy baja abundancia"
qiime feature-table filter-features \
  --i-table filtered-sequences/filtered-table.qza \
  --p-min-frequency 10 \
  --o-filtered-table filtered-sequences/feature-frequency-filtered-table.qza
echo "Asigne taxonomía"
qiime feature-classifier classify-sklearn \
  --i-classifier /home/evarela/tutorial/gg-13-8-99-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza \
  --p-n-jobs -1
echo "Creando la tabla de taxonomía"
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
echo "Eliminar características que contienen mitocondrias o cloroplasto"
qiime taxa filter-table \
  --i-table filtered-sequences/feature-frequency-filtered-table.qza \
  --i-taxonomy taxonomy.qza \
  --p-include p__ \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplast.qza
echo "Eliminar Archaea"
qiime taxa filter-table \
  --i-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplast.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude "k__Archaea" \
  --o-filtered-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea.qza
echo "Filtrar Eukaryota"
qiime taxa filter-table \
  --i-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea.qza \
  --i-taxonomy taxonomy.qza \
 --p-exclude "k__Eukaryota" \
  --o-filtered-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza
  
echo "Eliminar características que contienen mitocondrias o cloroplasto"
qiime taxa filter-seqs \
  --i-sequences rep-seqs.qza \
  --i-taxonomy taxonomy.qza \
  --p-include p__ \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplast.qza
echo "Eliminar Archaea"
qiime taxa filter-seqs \
  --i-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplast.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude "k__Archaea" \
  --o-filtered-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea.qza
echo "Eliminar Eukaryota"
qiime taxa filter-seqs \
--i-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea.qza \
--i-taxonomy taxonomy.qza \
--p-exclude "k__Eukaryota" \
--o-filtered-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza
echo "Cambiemos el nombre del archivo final filtrado para continuar."
mv filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza filtered-sequences/filtered-table2.qza
mv filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza filtered-sequences/filtered-rep-seqs.qza
echo "Visualice las clasificaciones taxonómicas"
qiime taxa barplot \
  --i-table filtered-sequences/filtered-table2.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization taxa-bar-plots.qzv
echo "Construya un árbol filogenético para análisis de diversidad filogenética"
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences filtered-sequences/filtered-rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza \
  --p-n-threads $cores
echo "Análisis de diversidad alfa y beta usando QIIME 2"
qiime feature-table summarize \
  --i-table filtered-sequences/filtered-table2.qza \
  --o-visualization filtered-sequences/filtered-table2.qzv \
  --m-sample-metadata-file sample-metadata_modified.tsv  
echo "Genere las métricas de diversidad alfa y beta"
rm -r -v /home/evarela/Paper_final/diversity-metrics-results/
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table filtered-sequences/filtered-table2.qza \
  --p-sampling-depth 13108 \
  --m-metadata-file sample-metadata_modified.tsv \
  --p-n-jobs-or-threads $cores \
  --output-dir diversity-metrics-results
echo "Análisis de diversidad alfa"
qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-metrics-results/faith_pd_vector.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization diversity-metrics-results/faith-pd-group-significance.qzv
qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-metrics-results/shannon_vector.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization diversity-metrics-results/shannon-group-significance.qzv
echo "Análisis de diversidad beta"
qiime diversity beta-group-significance \
  --i-distance-matrix diversity-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --m-metadata-column treatment \
  --o-visualization diversity-metrics-results/weighted-unifrac-life-stage-significance.qzv --p-pairwise
echo "herramienta Emperor"
qiime emperor plot \
  --i-pcoa diversity-metrics-results/weighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization diversity-metrics-results/weighted-unifrac-emperor-life-stage.qzv

echo "diversity alpha-rarefaction"
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 5000 \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization alpha-rarefaction.qzv
Date
cores=1
cd /home/evarela/Paper_final/
echo "Importe los datos de las secuencias a QIIME2"
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path se-33-manifest.tsv \
  --output-path single-end-demux.qza \
  --input-format SingleEndFastqManifestPhred33V2  
echo "Genere un archivo de visualización para examinar la calidad de las secuencias"
qiime demux summarize \
  --i-data single-end-demux.qza \
  --o-visualization single-demux-end.qzv
echo "Genere un archivo de visualización para examinar la calidad de las secuencias  denoise-single"
qiime dada2 denoise-single --i-demultiplexed-seqs single-end-demux.qza --p-trunc-len 253 --p-trim-left 0 --o-representative-sequences rep-seqs.qza --o-table table.qza --p-n-threads $cores --o-denoising-stats stats.qza
echo "Genere el stats-dada2.qzv"
qiime metadata tabulate \
  --m-input-file stats.qza \
  --o-visualization stats-dada2.qzv  
echo "Genere el FeatureTable y FeatureData summaries"
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample-metadata_modified.tsv 
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv
echo "Filtre el feature table (Total-frequency-based filtering"
qiime feature-table filter-samples \
  --i-table table.qza \
  --p-min-frequency 6000 \
  --o-filtered-table /home/evarela/Paper_final/filtered-sequences/filtered-table.qza
echo "Filtre características (features) con muy baja abundancia"
qiime feature-table filter-features \
  --i-table filtered-sequences/filtered-table.qza \
  --p-min-frequency 10 \
  --o-filtered-table filtered-sequences/feature-frequency-filtered-table.qza
echo "Asigne taxonomía"
qiime feature-classifier classify-sklearn \
  --i-classifier /home/evarela/tutorial/gg-13-8-99-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza \
  --p-n-jobs -1
echo "Creando la tabla de taxonomía"
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
echo "Eliminar características que contienen mitocondrias o cloroplasto"
qiime taxa filter-table \
  --i-table filtered-sequences/feature-frequency-filtered-table.qza \
  --i-taxonomy taxonomy.qza \
  --p-include p__ \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplast.qza
echo "Eliminar Archaea"
qiime taxa filter-table \
  --i-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplast.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude "k__Archaea" \
  --o-filtered-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea.qza
echo "Filtrar Eukaryota"
qiime taxa filter-table \
  --i-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea.qza \
  --i-taxonomy taxonomy.qza \
 --p-exclude "k__Eukaryota" \
  --o-filtered-table filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza
  
echo "Eliminar características que contienen mitocondrias o cloroplasto"
qiime taxa filter-seqs \
  --i-sequences rep-seqs.qza \
  --i-taxonomy taxonomy.qza \
  --p-include p__ \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplast.qza
echo "Eliminar Archaea"
qiime taxa filter-seqs \
  --i-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplast.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude "k__Archaea" \
  --o-filtered-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea.qza
echo "Eliminar Eukaryota"
qiime taxa filter-seqs \
--i-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea.qza \
--i-taxonomy taxonomy.qza \
--p-exclude "k__Eukaryota" \
--o-filtered-sequences filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza
echo "Cambiemos el nombre del archivo final filtrado para continuar."
mv filtered-sequences/table-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza filtered-sequences/filtered-table2.qza
mv filtered-sequences/rep-seqs-with-phyla-no-mitochondria-chloroplasts-archaea-eukaryota.qza filtered-sequences/filtered-rep-seqs.qza
echo "Visualice las clasificaciones taxonómicas"
qiime taxa barplot \
  --i-table filtered-sequences/filtered-table2.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization taxa-bar-plots.qzv
echo "Construya un árbol filogenético para análisis de diversidad filogenética"
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences filtered-sequences/filtered-rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza \
  --p-n-threads $cores
echo "Análisis de diversidad alfa y beta usando QIIME 2"
qiime feature-table summarize \
  --i-table filtered-sequences/filtered-table2.qza \
  --o-visualization filtered-sequences/filtered-table2.qzv \
  --m-sample-metadata-file sample-metadata_modified.tsv  
echo "Genere las métricas de diversidad alfa y beta"
rm -r -v /home/evarela/Paper_final/diversity-metrics-results/
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table filtered-sequences/filtered-table2.qza \
  --p-sampling-depth 13108 \
  --m-metadata-file sample-metadata_modified.tsv \
  --p-n-jobs-or-threads $cores \
  --output-dir diversity-metrics-results
echo "Análisis de diversidad alfa"
qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-metrics-results/faith_pd_vector.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization diversity-metrics-results/faith-pd-group-significance.qzv
qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-metrics-results/shannon_vector.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization diversity-metrics-results/shannon-group-significance.qzv
echo "Análisis de diversidad beta"
qiime diversity beta-group-significance \
  --i-distance-matrix diversity-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --m-metadata-column treatment \
  --o-visualization diversity-metrics-results/weighted-unifrac-life-stage-significance.qzv --p-pairwise
echo "herramienta Emperor"
qiime emperor plot \
  --i-pcoa diversity-metrics-results/weighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization diversity-metrics-results/weighted-unifrac-emperor-life-stage.qzv

echo "diversity alpha-rarefaction"
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 5000 \
  --m-metadata-file sample-metadata_modified.tsv \
  --o-visualization alpha-rarefaction.qzv

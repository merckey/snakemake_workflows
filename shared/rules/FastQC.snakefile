if paired:
    rule FastQC:
        input:
            "FASTQ/{sample}{read}.fastq.gz"
        output:
            "FastQC/{sample}{read}_fastqc.html"
        log:
            "FastQC/logs/FastQC.{sample}{read}.log"
        benchmark:
            "FastQC/.benchmark/FastQC.{sample}{read}.benchmark"
        threads: 2
        shell:
            fastqc_path+"fastqc -o FastQC {input} &> {log}"

else:
    rule FastQC_singleEnd:
        input:
            fastq_dir+"/{sample}.fastq.gz"
        output:
            "FastQC/{sample}_fastqc.html"
        log:
            "FastQC/logs/FastQC.{sample}.log"
        benchmark:
            "FastQC/.benchmark/FastQC.{sample}.benchmark"
        threads: 2
        shell:
            fastqc_path+"fastqc -o FastQC {input} &> {log}"

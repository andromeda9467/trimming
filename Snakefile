import os
import glob


ERR,FRR = glob_wildcards("rawReads/{err}_{frr}.fastq.gz")
TRIMMED_READ = ["1P","2P","1U","2U"]

rule all:
    input:
    #    expand("rawQC/{err}_{frr}_fastqc.{extension}", err = ERR, frr = FRR, extension = ["zip","html"]),
    #    "multiqc_data/multiqc_report.html",
        "plots/snakemake_dag.svg"
rule rawFastqc:
    input:
        raw_read = "rawReads/{err}_{frr}.fastq.gz"
    output:
        zip = "rawQC/{err}_{frr}_fastqc.zip",
        html = "rawQC/{err}_{frr}_fastqc.html"
    threads:
        2
    params:
        path = "rawQC/"
    shell: 
        """
        fastqc {input.raw_read} --threads {threads} -o {params.path}
        """
rule trimmomatic:
    input:
        read1 = "rawReads/{err}_1.fastq.gz",
        read2 = "rawReads/{err}_2.fastq.gz"
    output:
        paired_1 = "trimmedReads/{err}_1P.fastq.gz",
        paired_2 = "trimmedReads/{err}_2P.fastq.gz",
        un_paired_1= "trimmedReads/{err}_1U.fastq.gz",
        un_paired_2 = "trimmedReads/{err}_2U.fastq.gz",
    threads:
        2   
    params:
        basename = "trimmedReads/{err}.fastq.gz",
        log = "trimmedReads/{err}.log"
    shell: 
        """
        trimmomatic PE -threads {threads} {input.read1} {input.read2} \
        -baseout {params.basename} ILLUMINACLIP:adapters.fasta:2:30:10 \
         LEADING:2 TRAILING:2 SLIDINGWINDOW:4:28 MINLEN:50 2>{params.log}
        """

rule trimmedFastqc:
    input:
        trimmed_read = expand("trimmedReads/{err}_{read}.fastq.gz", err = ERR, read = TRIMMED_READ)
    output:
        html = expand("trimmedQC/{err}_{read}_fastqc.html",err = ERR, read = TRIMMED_READ),
        zip = expand("trimmedQC/{err}_{read}_fastqc.zip", err = ERR, read = TRIMMED_READ)    
    threads:
        2
    params:
        path = "trimmedQC/"
    shell: 
        """
        fastqc {input.trimmed_read} --threads {threads} -o {params.path}
        """
rule run_multiqc:
    input:
        fastqc_html = expand("trimmedQC/{err}_{read}_fastqc.html", err = ERR, read = TRIMMED_READ)
    output:
        multiqc = "multiqc_data/multiqc_report.html"
    params: 
        path = "multiqc_data/",
        path2 = "trimmedQC/"
    shell:
        """
        multiqc {params.path2} -o {params.path}
        """
rule plot:
    input:
        expand("rawQC/{err}_{frr}_fastqc.{extension}", err = ERR, frr = FRR, extension = ["zip","html"]),
        "multiqc_data/multiqc_report.html"        
    output:
        "plots/snakemake_dag.svg"
    script:
        "scripts/plot.py"       
        
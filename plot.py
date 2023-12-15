import os

cmd = f"snakemake --dag | dot -Tsvg > plots/snakemake_dag.svg"
os.system(cmd)
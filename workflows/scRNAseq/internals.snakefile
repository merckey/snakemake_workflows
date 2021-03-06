import glob
import os
import subprocess


### Functions ###################################################################

def get_sample_names(infiles):
    """
    Get sample names without file extensions
    """
    s = []
    for x in infiles:
        x = os.path.basename(x).replace(ext,"")
        try:
            x = x.replace(reads[0],"").replace(reads[1],"")
        except:
            pass
        s.append(x)
    return(sorted(list(set(s))))


def is_paired(infiles):
    """
    Check for paired-end input files
    """
    paired = False
    infiles_dic = {}
    for infile in infiles:
        fname = os.path.basename(infile).replace(ext, "")
        m = re.match("^(.+)("+reads[0]+"|"+reads[1]+")$", fname)
        if m:
            ##print(m.group())
            bname = m.group(1)
            ##print(bname)
            if bname not in infiles_dic:
                infiles_dic[bname] = [infile]
            else:
                infiles_dic[bname].append(infile)
    if infiles_dic and max([len(x) for x in infiles_dic.values()]) == 2:
        paired = True
    # TODO: raise exception if single-end and paired-end files are mixed
    return(paired)



### Variable defaults ##########################################################

try:
    indir = config["indir"]
except:
    indir = os.getcwd()

try:
    outdir = config["outdir"]
except:
    outdir = os.getcwd()

## paired-end read name extension
try:
    reads = config["reads"]
except:
    reads = ["_R1", "_R2"]

## FASTQ file extension
try:
    ext = config["ext"]
except:
    ext = ".fastq.gz"

## downsampling - number of reads
try:
    downsample = int(config["downsample"])
except:
    downsample = None

try:
    genome = config["genome"]
except:
    genome = None

try:
    mate_orientation = config["mate_orientation"]
except:
    mate_orientation = "--fr"


# IMPORTANT: When using snakemake with argument --config key=True, the
# string "True" is assigned to variable "key". Assigning a boolean value
# does not seem to be possible. Therefore, --config key=False will also
# return the boolean value True as bool("False") gives True.
# In contrast, within a configuration file config.yaml, assigment of boolean
# values is possible.
fastq_dir = ""
fastq_indir_trim = ""
trim = False

try:
    if config["trim"] == "trimgalore":
        trim = True
        fastq_dir = "FASTQ_TrimGalore"
        fastq_indir_trim = "FASTQ_barcoded"
    elif config["trim"] == "cutadapt":
        trim = True
        fastq_dir = "FASTQ_Cutadapt"
        fastq_indir_trim = "FASTQ_barcoded"
    else:
        trim = False
        fastq_dir = "FASTQ_barcoded"
except:
    trim = False
    fastq_dir = "FASTQ_barcoded"

try:
    trim_options = config["trim_options"]
except:
    trim_options = ""


try:
    bw_binsize = int(config["bw_binsize"])
except:
    bw_binsize = 10

try:
    barcode_pattern = config["barcode_pattern"]
except:
    barcode_pattern = ""

try:
	barcode_file = config["barcode_file"]
except:
	barcode_file = workflow.basedir+"/celseq_barcodes.192.txt"
    
try:
	filter_annotation = config["filter_annotation"]
except:
    filter_annotation = "''"

try:
	cell_names = config["cell_names"]
except: 
	cell_names = None
	
split_lib = config["split_lib"]

### Initialization #############################################################

if (cell_names != None and os.path.isfile(cell_names)==False):
	print("cell names file dowes not exist! Exit...\n")
	exit(1)

infiles = sorted(glob.glob(os.path.join(indir, '*'+ext)))
samples = get_sample_names(infiles)

## we just check if we have correctly paired fastq files
if not is_paired(infiles):
    print("This workflow requires paired-end read data!")
    exit(1)

## After barcode transfer to R2 we have only single end data / R2
paired = False

### barcode pattern extraction
pattern = re.compile("[N]+")

if pattern.search(barcode_pattern) is not None:
	UMI_offset = pattern.search(barcode_pattern).start() + 1 
	UMI_length = pattern.search(barcode_pattern).end() - UMI_offset + 1
else:
	print("Provided barcode pattern does not contain any 'N'! Exit...\n")
	exit(1)

pattern = re.compile("[X]+")

if pattern.search(barcode_pattern) is not None:
	CELLI_offset = pattern.search(barcode_pattern).start() + 1
	CELLI_length = pattern.search(barcode_pattern).end() - CELLI_offset + 1 
else:
	print("Provided barcode pattern does not contain any 'X'! Exit...\n")
	exit(1)

print("UMI_LEN:",UMI_length,"  UMI_offset:",UMI_offset,"\n")
print("CELLI_LEN:",CELLI_length,"  CELLI_offset:",CELLI_offset,"\n")

#cell_names_new = re.sub(".[^\.]*$", "",cell_names)

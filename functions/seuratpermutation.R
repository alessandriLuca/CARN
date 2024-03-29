
#' @title Seurat Permutation
#' @description This function executes a ubuntu docker that produces a specific number of permutation to evaluate clustering.
#' @param group, a character string. Two options: sudo or docker, depending to which group the user belongs
#' @param scratch.folder, a character string indicating the path of the scratch folder
#' @param file, a character string indicating the path of the file, with file name and extension included
#' @param nPerm, number of permutations to perform the pValue to evaluate clustering
#' @param permAtTime, number of permutations that can be computes in parallel
#' @param percent, percentage of randomly selected cells removed in each permutation
#' @param separator, separator used in count file, e.g. '\\t', ','
#' @param logTen, 1 if the count matrix is already in log10, 0 otherwise
#' @param pcaDimensions, 	0 for automatic selection of PC elbow.
#' @param seed, important value to reproduce the same results with same input
#' @param sparse, boolean for sparse matrix
#' @param format, output file format csv or txt
#' @param resolution, resolution for Seurat Analysis


#' @author Luca Alessandri, alessandri [dot] luca1991 [at] gmail [dot] com, University of Torino
#'
#' @return To write
#' @examples
#' \dontrun{
#'  system("wget http://130.192.119.59/public/section4.1_examples.zip")
#'  unzip("section4.1_examples.zip")
#'  setwd("section4.1_examples")

#'  system("wget ftp://ftp.ensembl.org/pub/release-94/gtf/homo_sapiens/Homo_sapiens.GRCh38.94.gtf.gz")
#'  system("gzip -d Homo_sapiens.GRCh38.94.gtf.gz")
#'  system("mv Homo_sapiens.GRCh38.94.gtf genome.gtf")
#'  scannobyGtf(group="docker", file=paste(getwd(),"bmsnkn_5x100cells.txt",sep="/"),
#'              gtf.name="genome.gtf", biotype="protein_coding", 
#'              mt=TRUE, ribo.proteins=TRUE,umiXgene=3)
#'  
#'  seuratBootstrap(group="docker",scratch.folder="/data/scratch/",
#'       file=paste(getwd(), "annotated_bmsnkn_5x100cells.txt", sep="/"), 
#'       nPerm=160, permAtTime=8, percent=10, separator="\t",
#'       logTen=0, pcaDimensions=6, seed=111)
#'}

#' @export
seuratPermutation <- function(group=c("sudo","docker"), scratch.folderDOCKER,scratch.folderHOST file, nPerm, permAtTime, percent, separator, logTen=0,pcaDimensions,seed=1111,sparse=FALSE,format="NULL",resolution=0.6){

if(!sparse){
  data.folder=dirname(file)
positions=length(strsplit(basename(file),"\\.")[[1]])
matrixNameC=strsplit(basename(file),"\\.")[[1]]
matrixName=paste(matrixNameC[seq(1,positions-1)],collapse="")
format=strsplit(basename(basename(file)),"\\.")[[1]][positions]
}else{
  matrixName=strsplit(dirname(file),"/")[[1]][length(strsplit(dirname(file),"/")[[1]])]
  data.folder=paste(strsplit(dirname(file),"/")[[1]][-length(strsplit(dirname(file),"/")[[1]])],collapse="/")
  if(format=="NULL"){
  stop("Format output cannot be NULL for sparse matrix")
  }
}
    
isDocker = is_running_in_docker()

    if (isDocker == TRUE){
      scratch.folderHOST = gsub("\\", "/", scratch.folderHOST)

      #creating a HOSTdocker variable for the datafolder
      host_parts = unlist(strsplit(scratch.folderHOST, "/"))
      docker_parts = unlist(strsplit(scratch.folderDOCKER, "/"))
      matches_path = paste(matches, collapse="/")
      HOSTpath = gsub(matches_path, "", scratch.folderHOST)

      #checking if the datafolder is inside a shared folder
      wd_parts = unlist(strsplit(data.folder, "/"))
      dmatches = intersect(docker_parts, wd_parts)
      dmatches_path = paste(dmatches, collapse="/")
      d_path = gsub(dmatches_path, "", data.folder)
      #creating the variable data.folderHOST
      data.folderHOST = paste(HOSTpath, d_path, sep="")
    }

    if(isDocker == FALSE){
      scratch.folderDOCKER = scratch.folderHOST
      data.folderHOST = data.folder
    }
  #running time 1
  ptm <- proc.time()
  #setting the data.folder as working folder
  if (!file.exists(data.folder)){
    cat(paste("\nIt seems that the ",data.folder, " folder does not exist\n"))
    exitStatus <- 2
    writeLines(as.character(exitStatus), "ExitStatusFile")
    return(2)
  }

  #storing the position of the home folder
  home <- getwd()
  setwd(data.folder)
  #initialize status
   exitStatus <- 0
   writeLines(as.character(exitStatus), "ExitStatusFile")

  #testing if docker is running
  test <- dockerTest()
  if(!test){
    cat("\nERROR: Docker seems not to be installed in your system\n")
    exitStatus <- 10
    writeLines(as.character(exitStatus), "ExitStatusFile")
    return(10)
    setwd(home)
  }



  #check  if scratch folder exist
  if (!file.exists(scratch.folderDOCKER)){
    cat(paste("\nIt seems that the ",scratch.folder, " folder does not exist\n"))
    exitStatus <- 3 
    writeLines(as.character(exitStatus), "ExitStatusFile")          
    setwd(data.folder)  
    return(3)
  }
  tmp.folder <- gsub(":","-",gsub(" ","-",date()))
  scrat_tmp.folderHOST=file.path(scratch.folderHOST, tmp.folder)
  scrat_tmp.folderDOCKER=file.path(scratch.folderDOCKER, tmp.folder)
  writeLines(scrat_tmp.folderDOCKER,paste(data.folder,"/tempFolderID", sep=""))
  cat("\ncreating a folder in scratch folder\n")
  dir.create(file.path(scrat_tmp.folderDOCKER))
  #preprocess matrix and copying files

if(separator=="\t"){
separator="tab"
}

 dir.create(paste(scrat_tmp.folder,"/",matrixName,sep=""))
 dir.create(paste(data.folder,"/Results",sep=""))
 if(sparse==FALSE){
file.copy(paste(,data.folder,"/",matrixName,".",format," "),paste(scrat_tmp.folder,"/",sep=""))
}else{
file.copy(paste(data.folder,"/",matrixName,"/ "),paste(scrat_tmp.folder,"/",sep=""))

}

dockerID_name="dockerID"
nr_dockerID = 0
while (file.exists(dockerID_name)){
    nr_dockerID = nr_dockerID + 1
    dockerID_name =paste0("dockerID" ,"_", nr_dockerID)
} 

  #executing the docker job
    params <- paste("--cidfile ",data.folder,"/", dockerID_name," -v ",scrat_tmp.folderHOST,":/scratch -v ", data.folderHOST, ":/data -d docker.io/repbioinfo/seuratpermutation Rscript /home/main.R ",matrixName," ",nPerm," ",permAtTime," ",percent," ",format," ",separator," ",logTen," ",pcaDimensions," ",seed," ",sparse," ",resolution,sep="")

resultRun <- runDocker(group=group, params=params)

  #waiting for the end of the container work
  if(resultRun==0){ items <- list.files(scrat_tmp.folderDOCKER)
          for (item in items) {
          file.copy(file.path(scrat_tmp.folderDOCKER, item), genomeFolder, recursive = TRUE, overwrite = TRUE)
        }
    #system(paste("cp ", scrat_tmp.folder, "/* ", data.folder, sep=""))
  }

  #saving log and removing docker container
  container.id <- readLines(paste(data.folder,"/",dockerID_name, sep=""), warn = FALSE)
   file.copy(paste("docker logs ", substr(container.id,1,12), " &> "),paste(data.folder,"/", substr(container.id,1,12),".log", sep=""))
   file.copy(paste("docker rm "),paste(container.id, sep=""))


  #Copy result folder
 cat("\n\nRemoving the temporary file ....\n")
  unlink(scrat_tmp.folderDOCKER,recursive=TRUE)
  #system("rm -fR dockerID")
  file.remove(c("tempFolderID"))
  #system(paste("cp ",paste(path.package(package="rCASC"),"containers/containers.txt",sep="/")," ",data.folder, sep=""))
  setwd(home)
} 
#' @title Cells count table size
#' @description This function executes a ubuntu docker that counts row and colums of a counts table.
#' @param group, a character string. Two options: sudo or docker, depending to which group the user belongs
#' @param scratch.folderDOCKER, a character string indicating the path of the scratch folder inside the docker
#' @param scratch.folderHOST, a character string indicating the path of the scratch folder inside the host. If not running from docker, this is the character string that indicates the path of the scratch.folder
#' @param file, a character string indicating the path of the file, with file name and extension included
#' @param separator, separator used in count file, e.g. '\\t', ','
#' @author Luca Alessandri, Sebastian Bucatariu, Agata D'Onofrio
#'
#' @return a file called dimensions.txt containing the number of row and columns of a cells counts table
#' @examples
#' \dontrun{
#' system("wget http://130.192.119.59/public/annotated_setPace_10000_noC5.txt.zip")
#' unzip("annotated_setPace_10000_noC5.txt.zip")
#' dimensions(group="docker", scratch.folder="/data/scratch",
#'             file=paste(getwd(),"annotated_setPace_10000_noC5.txt", sep="/"), separator="\t")

#'}
#' @export
dimensions <- function(group=c("sudo","docker"), scratch.folderHOST,scratch.folderDOCKER, file, separator){

#creating the data.folder and other variables
data.folder=dirname(file)
positions=length(strsplit(basename(file),"\\.")[[1]])
matrixNameC=strsplit(basename(file),"\\.")[[1]]
matrixName=paste(matrixNameC[seq(1,positions-1)],collapse="")
format=strsplit(basename(basename(file)),"\\.")[[1]][positions]

#checking if the function is running from Docker
isDocker = is_running_in_docker()

    if (isDocker == TRUE){
      scratch.folderHOST = gsub("\\\\", "/", scratch.folderHOST)

      #creating a HOSTdocker variable for the data.folder
      host_parts = unlist(strsplit(scratch.folderHOST, "/"))
      docker_parts = unlist(strsplit(scratch.folderDOCKER, "/"))
      matches_path = paste(matches, collapse="/")
      HOSTpath = gsub(matches_path, "", scratch.folderHOST)

      #checking if the data.folder is inside a shared folder
      wd_parts = unlist(strsplit(data.folder, "/"))
      dmatches = intersect(docker_parts, wd_parts)
      dmatches_path = paste(dmatches, collapse="/")
      d_path = gsub(dmatches_path, "", data.folder)
      #creating the variable data.folderHOST
      data.folderHOST = paste(HOSTpath, d_path, sep="")
    }

    if(isDocker == FALSE){
      #setting the variables that are unchanged if the function isn't running from docker
      scratch.folderDOCKER = scratch.folderHOST
      data.folderHOST = data.folder
    }
  
  #running time 1
  ptm <- proc.time()
    
  #setting the data.folder as working folder
  if (!file.exists(data.folder)){
    cat(paste("\nIt seems that the ",data.folder, " folder does not exist\n"))
    return(2)
  }

  #storing the position of the home folder
  home <- getwd()
  setwd(data.folder)
  
  #initialize status creating an ExitStatusFile
  exitStatus <- 0  
  writeLines(as.character(exitStatus), "ExitStatusFile")          
                                  

  #testing if docker is running
  test <- dockerTest()
  if(!test){
    cat("\nERROR: Docker seems not to be installed in your system\n")
    exitStatus <- 10  
    writeLines(as.character(exitStatus), "ExitStatusFile")
    setwd(home)
    return(10)
  }

  #check  if scratch folder exist
  if (!file.exists(scratch.folderDOCKER)){
    cat(paste("\nIt seems that the ",scratch.folderDOCKER, " folder does not exist\n"))
    exitStatus <- 3  
    writeLines(as.character(exitStatus), "ExitStatusFile")          
    setwd(data.folder)
    return(3)
  }

  #creating a temporary folder and a corresponding host variable
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
  file.copy(paste(data.folder,"/",matrixName,".",format," "),paste(scrat_tmp.folderDOCKER,"/",sep=""))

  #creating a dockerID file    
  dockerID_name="dockerID"
  nr_dockerID = 0
  while (file.exists(dockerID_name)){
      nr_dockerID = nr_dockerID + 1
      dockerID_name =paste0("dockerID" ,"_", nr_dockerID)
  } 

  #executing the docker job
  params <- paste("--cidfile ",data.folder,"/", dockerID_name," -v ",scrat_tmp.folderHOST,":/scratch -v ", data.folderHOST, ":/data -d docker.io/repbioinfo/r332.2017.01 Rscript /home/main.R ",matrixName," ",format," ",separator,sep="")

  resultRun <- runDocker(group=group, params=params)

  #waiting for the end of the container work
  if(resultRun==0){ items <- list.files(scrat_tmp.folderDOCKER)
    #system(paste("cp ", scrat_tmp.folder, "/* ", data.folder, sep=""))
    for (item in items) {
          file.copy(file.path(scrat_tmp.folderDOCKER, item), genomeFolder, recursive = TRUE, overwrite = TRUE)
        } 
  }

  #saving log and removing docker container
  container.id <- readLines(paste(data.folder,"/",dockerID_name, sep=""), warn = FALSE)
  file.copy(paste("docker logs ", substr(container.id,1,12), " &> "), paste(data.folder,"/", substr(container.id,1,12),".log", sep=""))
  file.copy(paste("docker rm "), paste(container.id, sep=""))


  #Copy result folder
  cat("Copying Result Folder")
   items <- list.files(scrat_tmp.folder)
    for (item in items) {	
      file.rename(file.path(scrat_tmp.folderDOCKER, item), file.path(data.folder, item))
   }

  #removing temporary folder
  cat("\n\nRemoving the temporary file ....\n")
  unlink(scrat_tmp.folderDOCKER,recursive=TRUE)
  file.remove(c("tempFolderID"))
   
  setwd(home)
} 

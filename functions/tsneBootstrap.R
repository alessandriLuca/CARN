#' @title Executing clustering with tSne
#' @description This function executes a ubuntu docker that produces a specific number of permutation using tSne as clustering tool.
#' @param group, a character string. Two options: sudo or docker, depending to which group the user belongs
#' @param scratch.folder, a character string indicating the path of the scratch folder
#' @param file, a character string indicating the path of the file, with file name and extension included
#' @param nPerm, number of permutations to be executed
#' @param permAtTime, number of permutations computed in parallel
#' @param percent, percentage of randomly selected cells removed in each permutation
#' @param range1, beginning of the range of clusters to be investigated
#' @param range2, end of the range of clusters to be investigated
#' @param separator, separator used in count file, e.g. '\\t', ','
#' @param logTen, 1 if the count matrix is already in log10, 0 otherwise
#' @param seed, important value to reproduce the same results with same input, default is 111
#' @param sp, minimun number of percentage of cells that has to be in common in a cluster, between two permutations, default 0.8
#' @param clusterPermErr, probability error in depicting the number of clusters in each permutation, default = 0.05
#' @param perplexity, number of close neighbors for each point. This parameter is specific for tSne. Default value is 10.  the performance of t-SNE is fairly robust under different settings of the perplexity. The most appropriate value depends on the density of your data.  A larger/denser dataset requires a larger perplexity. Typical values for the perplexity range between 5 and 50


#' @author Luca Alessandri, alessandri [dot] luca1991 [at] gmail [dot] com, University of Torino
#'
#' @return A folder Results containing a folder with the name of the experiment, which contains: VioPlot of silhouette cells value for each number of cluster used, a folder with the number of clusters used for SIMLR clustering, which contains: clusterP file with clustering results for each permutation, killedCell file with removed cells in each permutation, clustering.output a sommarize file with general information for each cells
#' @examples
#' \dontrun{
#' system("wget http://130.192.119.59/public/section4.1_examples.zip")
#' unzip("section4.1_examples.zip")
#' setwd("section4.1_examples")
#' tsneBootstrap(group="docker",scratch.folder="/data/scratch/",file=paste(getwd(), "bmsnkn_5x100cells.txt", sep="/"), nPerm=160, permAtTime=8, percent=10, range1=4, range2=6, separator="\t",logTen=0, seed=111, sp=0.8, clusterPermErr=0.05, perplexity=10)
#'}
#' @export

tsneBootstrap <- function(group=c("sudo","docker"), scratch.folderDOCKER, scratch.folderHOST, file, nPerm, permAtTime, percent, range1, range2, separator, logTen=0, seed=111, sp=0.8, clusterPermErr=0.05, perplexity=10){

  isDocker <- is_running_in_docker()
    if (isDocker == TRUE){
    scratch.folderHOST <- gsub("\\\\", "/", scratch.folderHOST)
    }
    if(isDocker == FALSE){
   scratch.folderDOCKER=scratch.folderHOST
   }

  permutationClustering(group=group, scratch.folderDOCKER=scratch.folderDOCKER, scratch.folderHOST=scratch.folderHOST, file=file, nPerm=nPerm, permAtTime=permAtTime, percent=percent, range1=range1, range2=range2, separator=separator, logTen=logTen, clustering="tSne", perplexity=10 , seed=seed, rK=0)
  permAnalysis(group=group, scratch.folderDOCKER=scratch.folderDOCKER, scratch.folderHOST=scratch.folderHOST, file=file, range1=range1, range2=range2, separator=separator, sp=sp, clusterPermErr=clusterPermErr, maxDeltaConfidence=0.01, minLogMean=0.05)


}

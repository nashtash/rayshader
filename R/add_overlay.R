#'@title Add Overlay
#'
#'@description Overlays an image (with a transparency layer) on the current map.
#'
#'@param hillshade A three-dimensional RGB array or 2D matrix of shadow intensities. 
#'@param overlay A three or four dimensional RGB array, where the 4th dimension represents the alpha (transparency) channel. 
#'If the array is 3D, `alphacolor` should also be passed to indicate transparent regions.
#'@param alphacolor Default `NULL`. If `overlay` is a 3-layer array, this argument tells which color is interpretted as completely transparent.
#'@param alphalayer Default `1`. Defines minimum tranparaency of layer. If transparency already exists in `overlay`, the way `add_overlay` combines 
#'the two is determined in argument `layeralphamethod`.
#'@param alphamethod Default `max`. Method for dealing with pre-existing transparency with `layeralpha`. 
#'If `max`, converts all alpha levels higher than `layeralpha` to the value set in `layeralpha`.
#'If `multiply`, multiples all pre-existing alpha values with `layeralpha`.
#'If `none`, keeps existing tranparencies and only changes opaque entries.
#'@param gamma_correction Default `TRUE`. Controls gamma correction when adding colors. Default exponent of 2.2.
#'@return Hillshade with overlay.
#'@export
#'@examples
#'#TBD
add_overlay = function(hillshade, overlay, alphacolor=NULL, 
                       alphalayer = 1, alphamethod = "max", gamma_correction = TRUE) {
  flipud = function(x) {
    x[nrow(x):1,]
  }
  if(any(alphalayer > 1 || alphalayer < 0)) {
    stop("Argument `alphalayer` must not be less than 0 or more than 1")
  }
  if(class(hillshade) != "array") {
    if (class(hillshade) == "matrix") {
      if(any(hillshade > 1 | hillshade < 0)) {
        stop("Error: Not a shadow matrix. Intensities must be between 0 and 1. Pass your elevation matrix to ray_shade/lamb_shade/ambient_shade/sphere_shade first.")
      }
      temp = array(0,dim = c(nrow(hillshade),ncol(hillshade),3))
      temp[,,1] = flipud(t(hillshade))
      temp[,,2] = flipud(t(hillshade))
      temp[,,3] = flipud(t(hillshade))
      hillshade = temp
    } else {
      stop("Argument `hillshade` must be a RGB 3/4D array or 1D shadow matrix.")
    }
  } 
  if(gamma_correction) {
    hillshade = hillshade ^ 2.2
  }
  overlay[,,1:3] = overlay[,,1:3] ^ 2.2
  if((dim(overlay)[3] == 3 || (dim(overlay)[3] == 4 && all(overlay[,,4] == 1))) && alphalayer == 1) {
    if(is.null(alphacolor)) {
      stop("If `overlay` array is only 3D (or is completely opaque), argument `alphacolor` must be defined")
    }
    colorvals = col2rgb(alphacolor)/255
    alphalayer1 = overlay[,,1] == colorvals[1] & overlay[,,2] == colorvals[2] & overlay[,,3] == colorvals[3]
    for(i in 1:dim(hillshade)[1]) {
      for(j in 1:dim(hillshade)[2]) {
        if(!alphalayer1[j,i]) {
          hillshade[i,j,1] = overlay[j,i,1]
          hillshade[i,j,2] = overlay[j,i,2]
          hillshade[i,j,3] = overlay[j,i,3]
        }
      }
    }
    if(gamma_correction) {
      hillshade = hillshade^(1/2.2)
    }
    return(hillshade)
  }
  
  if(dim(overlay)[3] == 4 || alphalayer != 1) {
    if(dim(overlay)[3] == 3) {
      temp = array(alphalayer,dim = c(ncol(overlay),nrow(overlay),4))
      temp[,,1:3] = overlay[,,1:3]
      overlay = temp
    }
    if(alphalayer != 1) {
      if(alphamethod == "max") {
        alphamat = overlay[,,4]
        alphamat[alphamat > alphalayer] = alphalayer
        overlay[,,4] = alphamat
      } else if (alphamethod == "multiply") {
        overlay[,,4] =  overlay[,,4] * alphalayer
      } else if (alphamethod == "none") {
        alphamat = overlay[,,4]
        alphamat[alphamat == 1] = alphalayer
        overlay[,,4] = alphamat
      }
    }
    # overlay = aperm(overlay, c(1,2,3))
    if(!is.null(alphacolor)) {
      colorvals = col2rgb(alphacolor)/255
      alphalayer1 = overlay[,,1] == colorvals[1] & overlay[,,2] == colorvals[2] & overlay[,,3] == colorvals[3]
      overlay[,,4][alphalayer1] = 0
    }
    if(any(overlay[,,4] > 1) | any(overlay[,,4] < 0) ) {
      stop("Alpha channel in `overlay` can't be greater than 1 or less than 0")
    }
    hillshade[,,1] = hillshade[,,1] * (1 - overlay[,,4]) + overlay[,,1] * overlay[,,4]
    hillshade[,,2] = hillshade[,,2] * (1 - overlay[,,4]) + overlay[,,2] * overlay[,,4]
    hillshade[,,3] = hillshade[,,3] * (1 - overlay[,,4]) + overlay[,,3] * overlay[,,4]
    hillshade[hillshade > 1] = 1
    if(gamma_correction) {
      hillshade = hillshade^(1/2.2)
    }
    return(hillshade)
  }
}
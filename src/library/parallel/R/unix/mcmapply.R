#  File src/library/parallel/R/unix/mcmapply.R
#  Part of the R package, https://www.R-project.org
#
#  Copyright (C) 1995-2019 The R Core Team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  https://www.R-project.org/Licenses/

mcmapply <-
    function(FUN, ..., MoreArgs = NULL, SIMPLIFY = TRUE, USE.NAMES = TRUE,
             mc.preschedule = TRUE, mc.set.seed = TRUE,
             mc.silent = FALSE, mc.cores = getOption("mc.cores", 2L),
             mc.cleanup = TRUE, affinity.list = NULL)
{
    FUN <- match.fun(FUN)
    dots <- list(...)
    if(!length(dots)) return(list())
    lens <- lengths(dots)
    n <- max(lens)
    if(n && min(lens) == 0L)
        stop("Zero-length inputs cannot be mixed with those of non-zero length")
    answer <- if(n < 2L){ 
      ## ensure that it runs on the right core 
      if(!is.null(affinity.list)){
        save <- mcaffinity()
        mcaffinity(affinity.list[[1]])
      }
      answer <- .mapply(FUN, dots, MoreArgs)
        # .mapply will not catch errors thrown by FUN
      if(!is.null(affinity.list)) mcaffinity(save)
      answer
    } else {    
        ## recycle shorter vectors
        X <- if (!all(lens == n))
            lapply(dots, function(x) rep(x, length.out = n))
        else dots
        do_one <- function(indices, ...) {
            dots <- lapply(X, function(x) x[indices])
            .mapply(FUN, dots, MoreArgs)
        }
        answer <- mclapply(seq_len(n), do_one, mc.preschedule = mc.preschedule,
                           mc.set.seed = mc.set.seed, mc.silent = mc.silent,
                           mc.cores = mc.cores, mc.cleanup = mc.cleanup, 
                           affinity.list = affinity.list)
        answer <- lapply(answer, function(x) {
            if (inherits(x, "try-error")) {
                SIMPLIFY <<- FALSE # protect attributes from simplify2array()
                list(x) # protect attributes from c()
            } else
                x
        })
        do.call(c, answer)
    }
    if (USE.NAMES && length(dots)) {
        if (is.null(names1 <- names(dots[[1L]])) && is.character(dots[[1L]]))
            names(answer) <- dots[[1L]]
        else if (!is.null(names1))
            names(answer) <- names1
    }
    if (!identical(SIMPLIFY, FALSE) && length(answer))
        simplify2array(answer, higher = (SIMPLIFY == "array"))
    else answer
}

mcMap <- function (f, ...)
{
    f <- match.fun(f)
    mcmapply(f, ..., SIMPLIFY = FALSE, mc.silent = TRUE)
}

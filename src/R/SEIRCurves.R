library(tidyverse)

enter_path_here <- "/Users/sydney/Dropbox/JAKOB-SYDNEY/full_10_000_nodes"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*-0.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != "_info.csv"]
files <- files[!str_detect(files, "infectionChance")]
#files <- files[!grepl("regular", files)]
pattern <- c("-0.1-", "-0.2-", "-0.3-")
files <- files[grepl(paste(pattern, collapse = "|"), files)]

# for(i in 1:(length(files)/4)){
#   lowerCounter <- 1+(i-1)*4
#   upperCounter <- 4*i
#   filesReduced <- files[lowerCounter:upperCounter]

dataSetFull <- data.frame()

  for(file in files){
    dataSetNew <- read.csv(file)
    dataSetNew$ID <- seq.int(nrow(dataSetNew))
    dataSetNew$Network <- str_split(file, "-")[[1]][[1]]
    dataSetNew$BaseProb <- str_split(file, "-")[[1]][[2]]
    dataSetNew$Scenario <- str_split(file, "-")[[1]][[3]]
    dataSetNew$DiseaseState <- str_split(file, "-")[[1]][[4]]
    #dataSetNew$DiseaseState <- str_remove(dataSetNew$DiseaseState, ".csv")
    if (length(str_split(file, "-")[[1]]) == 5) {
     dataSetNew$lag <- str_split(file, "-")[[1]][[5]]
    } else {
      dataSetNew$lag <- 0
    }
    #dataSetNew$DiseaseState <- substr(dataSetNew$DiseaseState,1,nchar(dataSetNew$DiseaseState)-4)
    dataSetNew <- pivot_longer(dataSetNew, cols = seed1:seed100)
    dataSetFull <- rbind(dataSetFull, dataSetNew)
  }

  dataSetGrouped <- dataSetFull %>% group_by(Network, Scenario, DiseaseState, ID, lag, BaseProb) %>% summarise(mean = mean(value), sd = sd(value))
  dataSetGrouped <- dataSetGrouped %>% ungroup()
  dataSetGrouped <- dataSetGrouped %>% mutate(ymin = case_when(mean-sd > 0 ~ mean-sd, 
                                                              .default = 0)) %>%
                                        mutate(lag = case_when(lag == "0.csv" ~ 0, 
                                                                lag == "1.csv" ~ 1,
                                                                lag == "2.csv" ~ 2,))
  for(network in unique(dataSetGrouped$Network)) {
    for(scenario in unique(dataSetGrouped$Scenario)) {
      for(baseprob in unique(dataSetGrouped$BaseProb)) {
  plot <- ggplot(dataSetGrouped %>% filter(Network == network) %>% filter(Scenario == scenario) %>% filter(BaseProb == baseprob), aes(x=ID, y = mean)) +
    geom_line(aes(color=DiseaseState), size = 3) +
    geom_ribbon(aes(y = mean, ymin= ymin, ymax = mean+sd, fill = DiseaseState), alpha = 0.2) +
    theme_minimal() +
   scale_y_log10(breaks = c(0.1, 1, 10, 100, 1000,10000), labels = c(0.1, 1, 10, 100, 1000,10000)) +
    xlab("Time step") + 
    ylab("Number of nodes") +
    xlim(c(0,200)) +
  #  ylim(c(0,1000)) +
    theme(legend.position = "bottom", legend.title = element_blank()) +
    theme(legend.position = "bottom", legend.title = element_blank()) +
    theme(axis.ticks.x = element_line(),
      axis.ticks.y = element_line(),
      axis.ticks.length = unit(5, "pt")) +
    guides(color = guide_legend(nrow = 2, byrow = TRUE)) +
    theme(text = element_text(size = 45))

  file_name <- paste0(as.character(network),"-", as.character(dataSetGrouped$lag), "lag-", as.character(scenario), "-", as.character(baseprob), "-logscale-SEIRcurve.pdf")
  ggsave(file_name, plot, dpi = 500, w = 9, h = 9)
      }
    }
  }

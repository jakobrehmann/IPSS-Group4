library(tidyverse)

enter_path_here <- "/Users/sydney/Dropbox/JAKOB-SYDNEY/full_10_000_nodes"
setwd(enter_path_here)

files <- list.files(path=enter_path_here, pattern="*infectious-0.csv", full.names=FALSE, recursive=FALSE)
files <- files[files != "_info.csv"]
files <- files[!str_detect(files, "infectionChance")]
pattern <- c("-0.1-", "-0.2-", "-0.3-")
files <- files[grepl(paste(pattern, collapse = "|"), files)]

dataSetFull <- data.frame()

  for(file in files){
    dataSetNew <- read.csv(file)
    dataSetNew$ID <- seq.int(nrow(dataSetNew))
    dataSetNew$Network <- str_split(file, "-")[[1]][[1]]
    dataSetNew$BaseProb <- str_split(file, "-")[[1]][[2]]
    dataSetNew$DiseaseState <- str_split(file, "-")[[1]][[3]]
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

  dataSetGrouped <- dataSetFull %>% group_by(Network, DiseaseState, ID, lag, BaseProb) %>% summarise(mean = mean(value), sd = sd(value))
  dataSetGrouped <- dataSetGrouped %>% ungroup()
  dataSetGrouped <- dataSetGrouped %>% mutate(ymin = case_when(mean-sd > 0 ~ mean-sd, 
                                                              .default = 0)) %>%
                                        mutate(lag = case_when(lag == "0.csv" ~ 0, 
                                                                lag == "1.csv" ~ 1,
                                                                lag == "2.csv" ~ 2,))

  dataSetGrouped <- dataSetGrouped %>% mutate(BaseProbLabel = case_when(
          BaseProb == 0.3 ~ "Infection probability = 0.3",
          BaseProb == 0.2 ~ "Infection probability = 0.2",
          BaseProb == 0.1 ~ "Infection probability = 0.1"))
  dataSetGrouped$BaseProbLabel <- as.factor(dataSetGrouped$BaseProbLabel)
  dataSetGrouped$BaseProbLabel <- ordered (dataSetGrouped$BaseProbLabel, levels = c("Infection probability = 0.3", "Infection probability = 0.2","Infection probability = 0.1"))
    
    for(network in unique(dataSetGrouped$Network)){
    plot <- ggplot(dataSetGrouped %>% filter(DiseaseState != "local2") %>% filter(Network == network), aes(x=ID, y = mean)) +
    geom_line(aes(color = DiseaseState), size = 2.5) +
    xlab("Time step") +
    ylab("Number of nodes") +
    xlim(c(0, 200)) +
    theme_minimal() +
    theme(legend.position = "bottom", legend.title = element_blank()) +
    theme(legend.position = "bottom", legend.title = element_blank()) +
    theme(axis.ticks.x = element_line(),
      axis.ticks.y = element_line(),
      axis.ticks.length = unit(5, "pt")) +
    scale_color_brewer(palette = "Dark2") +
    theme(text = element_text(size = 45)) +
    facet_wrap(~ BaseProbLabel, nrow = 3)

    file_name <- paste0(as.character(network),"-", as.character(dataSetGrouped$lag), "lag-ICurves.pdf")
    ggsave(file_name, plot, dpi = 500, w = 15, h = 10)
    }

library(tidyverse)

enter_path_here <- "/Users/sydney/Documents/data/2024-01-02T115022"
setwd(enter_path_here)

# Reading in of files, the user needs to change line 9 according to the network they are interested in
files <- list.files(path=enter_path_here, pattern="*recovered", full.names=FALSE, recursive=FALSE)
files <- files[files != paste0(enter_path_here, "_info.csv")]
network_top <- "smallworldreg" #Possible values: "random", "regular", "smallworld", "preferential"
files <- files[grepl(network_top, files)]

dataSetFull <- data.frame()

for (i in 1:(length(files))){
  filesReduced <- files[i]
  for (file in filesReduced){
    dataSetNew <- read.csv(file)
    dataSetNew$ID <- seq.int(nrow(dataSetNew))
    dataSetNew$BaseSuscep <- str_split(file, "-")[[1]][[2]]
    dataSetNew$Strategy <- str_split(file, "-")[[1]][[3]]
    if (length(str_split(file, "-")[[1]]) == 5) {
    dataSetNew$lag <- str_split(file, "-")[[1]][[5]]
    } else {
      dataSetNew$lag <- 0
    }
    dataSetNew <- pivot_longer(dataSetNew, cols = seed1:seed100)
    dataSetFull <- rbind(dataSetFull, dataSetNew)
  }
}

dataSetGrouped <- dataSetFull
noTimeSteps <- max(dataSetGrouped$ID)
dataSetGrouped <- dataSetGrouped %>% filter(ID == noTimeSteps) %>%
  filter(value > 5) %>%
  group_by(BaseSuscep, Strategy, ID, lag) %>%
  summarise(mean = mean(value), sd = sd(value))
dataSetGrouped <- dataSetGrouped %>% ungroup()


ggplot(dataSetGrouped, aes(x = Strategy, y = mean)) +
  geom_point() +
  ylab("Pandemic size (# of recovered, after 200 steps") +
  xlab("Considered szenario") +
  theme_minimal() +
  facet_wrap(~BaseSuscep) +
  ggtitle(network_top) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#ggsave(paste0(str_split(file, "-")[[1]][[1]], "ScenarioVsPandemicSize.pdf"), dpi = 500, w = 9, h = 6)   

dataSetGrouped$BaseSuscep <- as.numeric(dataSetGrouped$BaseSuscep)

dataSetGrouped <- dataSetGrouped %>% filter(Strategy != "local2")

ggplot(dataSetGrouped %>% filter(lag == "0.csv"), aes(x = BaseSuscep, y = mean)) +
  geom_line(aes(color = Strategy), size = 2.5) +
  scale_color_brewer(palette = "Dark2") +
  xlab("w") +
  ylab("Pandemic size") +
  xlab("Base Infection Probability") +
  theme_minimal() +
  #ggtitle(network_top) +
  theme(text = element_text(size = 45)) +
  scale_x_continuous(breaks = seq(from = 0.1, to = 0.3, by = 0.025)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  theme(legend.position = "bottom", legend.title = element_blank()) +
  theme(axis.ticks.x = element_line(),
        axis.ticks.y = element_line(),
        axis.ticks.length = unit(5, "pt")) +
  guides(color=guide_legend(nrow=2, byrow=TRUE))

if (length(str_split(file, "-")[[1]]) == 5){
ggsave(paste0(str_split(file, "-")[[1]][[1]], "-0lag", "BaseSuscepVsPandemicSize.pdf"), dpi = 500, w = 9, h = 9) 
} else{ 
ggsave(paste0(str_split(file, "-")[[1]][[1]], "BaseSuscepVsPandemicSize.pdf"), dpi = 500, w = 9, h = 9)   
}


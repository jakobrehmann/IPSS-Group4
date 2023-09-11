library(tidyverse)
library(RColorBrewer)
library(matrixStats)

#Hom, Het, Het_Ass
data_hom <- read_csv("/Users/sydney/git/IPSS-Group4/src/julia/preferential-homogenous.csv")
data_het <- read_csv("/Users/sydney/git/IPSS-Group4/src/julia/preferential-heterogenous.csv")
data_het_ass <- read_csv("/Users/sydney/git/IPSS-Group4/src/julia/smallworld-heterogenous_assortative.csv")

data_hom <- data_hom %>%
            mutate(mean = rowMeans(data_hom)/10) %>%
            mutate(standard_deviation = apply(data_hom[, -1], 1, sd)/10) %>%
            mutate(scenario = "hom") %>%
            mutate(max = (rowMaxs(data.matrix(data_hom)))) %>%
            mutate(min = (rowMins(data.matrix(data_hom)))) %>%
            mutate(approx_sd = (rowMaxs(data.matrix(data_hom)) - rowMins(data.matrix(data_hom))) / 4)
data_hom$time_step <- seq.int(nrow(data_hom))

data_het <- data_het %>% mutate(mean = rowMeans(data_het)/10) %>%
            mutate(standard_deviation = (apply(data_het, 1, sd))/10) %>%
            mutate(scenario = "het") %>% 
            mutate(max = (rowMaxs(data.matrix(data_het)))) %>%
            mutate(min = (rowMins(data.matrix(data_het)))) 
data_het$time_step <- seq.int(nrow(data_het))

data_het_ass <- data_het_ass %>% mutate(mean = rowMeans(data_het_ass)/10) %>%
            mutate(standard_deviation = (apply(data_het_ass, 1, sd))/10) %>%
            mutate(scenario = "het_assortative") %>%
             mutate(max = (rowMaxs(data.matrix(data_het_ass)))) %>%
            mutate(min = (rowMins(data.matrix(data_het_ass))))
data_het_ass$time_step <- seq.int(nrow(data_het_ass))

means_sd_hom <- data.frame(data_hom$mean, data_hom$standard_deviation, data_hom$scenario, data_hom$time_step,data_hom$max, data_hom$min)
colnames(means_sd_hom) <- c("mean", "standard_deviation", "scenario", "time_step", "max", "min")
means_sd_het <- data.frame(data_het$mean, data_het$standard_deviation, data_het$scenario, data_het$time_step,data_het$max, data_het$min)
colnames(means_sd_het) <- c("mean", "standard_deviation", "scenario", "time_step", "max", "min")
means_sd_het_ass <- data.frame(data_het_ass$mean, data_het_ass$standard_deviation, data_het_ass$scenario, data_het_ass$time_step, data_het_ass$max, data_het_ass$min)
colnames(means_sd_het_ass) <- c("mean", "standard_deviation", "scenario", "time_step", "max", "min")

means_sd <- means_sd_hom
means_sd <- rbind(means_sd, means_sd_het)
means_sd <- rbind(means_sd, means_sd_het_ass)

ggplot(means_sd, aes(x = time_step)) +
geom_ribbon(aes(ymin = mean-standard_deviation, ymax = mean+standard_deviation, fill = scenario), alpha = 0.3) +
geom_line(aes(y = mean, color = scenario), linewidth = 1.4) +
theme_minimal() +
xlab("Time step") +
xlim(0,200) +
ylim(-1,47) +
ylab("Percentage of the \n population infected") +
theme(legend.title = element_blank()) +
theme(legend.position = "bottom") +
theme(text = element_text(size = 25)) +
theme(axis.ticks.x = element_line(),
                   axis.ticks.y = element_line(),
                   axis.ticks.length = unit(5, "pt"))

#Careful vs risky
het_ass <- read_csv("/Users/sydney/git/IPSS-Group4/smallworld-heterogenous_assortativeASS.csv")
het_ass <- het_ass %>% mutate(mean = rowMeans(het_ass)) %>%
            mutate(standard_deviation = (apply(het_ass, 1, sd))) %>%
            mutate(scenario = "low risk exposure") %>%
            mutate(max = (rowMaxs(data.matrix(het_ass)))) %>%
            mutate(min = (rowMins(data.matrix(het_ass))))
het_ass$time_step <- seq.int(nrow(het_ass))

het_ass2 <- read_csv("/Users/sydney/git/IPSS-Group4/smallworld-heterogenous_assortative-ASS2.csv")
het_ass2 <- het_ass2 %>% mutate(mean = rowMeans(het_ass2)) %>%
            mutate(standard_deviation = (apply(het_ass2, 1, sd))) %>%
            mutate(scenario = "high risk exposure") %>% 
            mutate(max = (rowMaxs(data.matrix(het_ass2)))) %>%
            mutate(min = (rowMins(data.matrix(het_ass2))))
het_ass2$time_step <- seq.int(nrow(het_ass2))

means_sd_ass <- data.frame(het_ass$mean, het_ass$standard_deviation, het_ass$scenario, het_ass$time_step, het_ass$max, het_ass$min)
colnames(means_sd_ass) <- c("mean", "standard_deviation", "scenario", "time_step", "max", "min")
means_sd_ass2 <- data.frame(het_ass2$mean, het_ass2$standard_deviation, het_ass2$scenario, het_ass2$time_step, het_ass2$max, het_ass2$min)
colnames(means_sd_ass2) <- c("mean", "standard_deviation", "scenario", "time_step", "max", "min")

means_sd <- means_sd_ass
means_sd <- rbind(means_sd, means_sd_ass2)
means_sd <- rbind(means_sd, means_sd_het_ass)

ggplot(means_sd, aes(x = time_step)) +
geom_ribbon(aes(ymin = mean-standard_deviation, ymax = mean+standard_deviation, fill = scenario), alpha = 0.3) +
geom_line(aes(y = mean, color = scenario), linewidth = 1.4) +
theme_minimal() +
xlab("Time step") +
 ylab("Percentage of the \npopulation infected") +
theme(legend.title = element_blank()) +
theme(legend.position = "bottom") +
theme(text = element_text(size = 15)) +
theme(axis.ticks.x = element_line(),
                   axis.ticks.y = element_line(),
                   axis.ticks.length = unit(5, "pt"))


# 霍恩博尔加斯舍恩湖鹤群观测数据分析报告 (1994–2024)
### 该数据源自于`https://www.hornborga.com/naturen/transtatistik/`
### 由Contributor `Carl Borstell`提供。
### 作者：lawiet

>[!note]
>背景介绍
>30多年来，停靠在瑞典西约特兰州霍恩博尔加斯约恩湖（“霍恩堡湖”）的鹤一直从 春季和秋季的霍恩博尔加舍恩野外站 ，因为它们在每年的迁徙过程中经过。
>接下来从三个角度出发分析霍恩堡湖的鹤迁徙过程的观测数据
>1. 在过去的 30 年里，霍恩博尔加斯舍恩湖的鹤数量变化情况
>2. 如果您想看到成千上万的鹤，一年中什么时候是最佳游览时间？
>3. 探究天气干扰

### 数据清洗

由于数据存在部分缺失（如：NA） 对现有数据的缺失项剔除，并修改数据类型（比如时间数据date），将其拆分成year,month,week_of_year等等variables方便后续分析

```R
cranes <- read.csv(file_path)
cleaned_cranes <- cranes %>% 
  mutate(date = as.character(date)) %>%
  mutate(date = as.Date(date, format = "%Y/%m/%d")) %>%
  mutate(
    year = format(date, "%Y"),
    month = format(date, "%m"),
    week_of_year = lubridate::week(date) 
  ) %>%

  filter(!is.na(observations)) %>% 
  mutate(observations = as.numeric(observations))
glimpse(cleaned_cranes)
```

## Q1：在过去的 30 年里，霍恩博尔加斯舍恩湖的鹤数量变化情况

- 在清洗后的数据中，我们可以将每年都分成一组，然后统计每一组的最大观测数（observations）。按照年份作为横轴，年度最大观测数为纵轴，我们可以获得相关的折线图，并推算出线性回归（红色虚线表示），如下图（Annual Maximum Crane Observations Trend）：
```R
yearly_max_counts <- cleaned_cranes %>%
  group_by(year) %>%
  summarise(
    max_count = max(observations, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  mutate(year = as.numeric(year))
print(yearly_max_counts)
```
```R
yearly_max_plot <-yearly_max_counts %>% 
  ggplot(aes(x = year, y = max_count)) +
  geom_line(color = "#8C8CFF", linewidth = 1) +
  geom_point(color = "#0000ff", size = 1.5) +
  geom_smooth(method = "lm", color = "red", se = TRUE, linetype = "dashed") +
  labs(
    title = "Annual Maximum Crane Observations Trend",
    x = "Year",
    y = "Maximum Observation Count (Thousands)") +
  scale_y_continuous(labels = scales::label_number(scale = 1/1000, suffix = "K")) +
  theme_minimal()
print(yearly_max_plot)
```

- 结论：霍恩博尔加斯舍恩湖作为鹤类栖息地的重要性在不断提升，鹤群的数量在过去 30 年里增长显著。
## Q2：如果您想看到成千上万的鹤，一年中什么时候是最佳游览时间？

- 回答该问题，最重要的是统计全部年份中每一周鹤的平均观测数(Average Observation Count)。于是我们可以将week_of_year相同的分一组，并计算每一组的平均观测数。如下图所示（Seasonal Pattern of Crane Observations），其中红色点线表明观测数达到5千。

```R
weekly_avg_counts <- cleaned_cranes %>% 
  group_by(week_of_year) %>% 
  summarise(
    avg_count = mean(observations),
    .groups = 'drop'
  )
print(weekly_avg_counts)
```

```R
weekly_avg_plot <- weekly_avg_counts %>%
  ggplot(aes(x = week_of_year, y = avg_count)) +
  geom_col(fill = "#009E73") +
  geom_hline(yintercept = 5000, linetype = "dotted", color = "red", linewidth = 1) +
  labs(
    title = "Seasonal Pattern of Crane Observations",
    x = "Week of the Year (1-52)",
    y = "Average Observation Count (Thousands)") +
  scale_y_continuous(labels = scales::label_number(scale = 1/1000, suffix = "K")) +
  scale_x_continuous(breaks = seq(0, 52, by = 4)) +
  theme_minimal()
print(weekly_avg_plot)
```

- 结论：若想看到更多的鹤，优先选择三月中旬到四月初，其次是九月到十月。

## Q3：测算天气干扰频率
观测记录中的天气干扰频率（Weather Disruption Frequency）可以作为衡量该地区采样环境稳定性的指标。天气干扰最直接的影响是导致“取消观测”。我们可以计算干扰发生的频率，以及在干扰期间数据缺失（NA）的比例。

```R
weather_impact_freq <- cranes %>%
  mutate(year = format(as.Date(date), "%Y")) %>%
  group_by(year) %>%
  summarise(
    total_days = n(),
    disrupted_days = sum(weather_disruption == TRUE),
    disruption_rate = disrupted_days / total_days,
    missing_obs = sum(is.na(observations) & weather_disruption == TRUE)
  )

ggplot(weather_impact_freq, aes(x = as.numeric(year), y = disrupted_days)) +
  geom_col(fill = "steelblue") +
  labs(title = "Annual Weather Disruption Frequency", 
       x = "Year", y = "Number of Disrupted Days")
```

- 结论：如果这种干扰频率与迁徙高峰期高度重合，将显著增加监测工作的不确定性。这提示我们在未来的监测规划中，可能需要增加自动化观测手段（如卫星追踪或远程监控），以弥补极端天气下人工观测的覆盖不足。



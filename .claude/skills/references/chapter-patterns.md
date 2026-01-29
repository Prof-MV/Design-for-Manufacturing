# Bookdown Chapter Patterns for Process Engineering

## Standard Chapter Structure

### Important: Header Formatting Rules
**All chapter headers must:**
- Be descriptive and professional
- Contain NO emojis or decorative symbols
- Use proper cross-reference labels
- Follow consistent capitalization

**Good examples:**
```markdown
# Plant Layout and Material Handling {#chap-05-layout}
## Principles of Efficient Workflow {#sec:workflow-principles}
### Calculating Space Requirements {#sec:space-calc}
```

**Bad examples (avoid these):**
```markdown
# 🏭 Plant Layout and Material Handling  ❌ (contains emoji)
## principles of workflow  ❌ (inconsistent capitalization)
### Space Requirements  ❌ (missing cross-reference label)
```

### 1. Chapter Header and Setup
```markdown
# Chapter Title {#chapter-label}

```{r setup-XX, include=FALSE}
# include the helpers.R file for pdf output of youtube on pdfs as a clickable link
source("R/helpers.R")
# include the required packages to make sure the page can be built.
source("R/required_packages.R")
```
```

### 2. Learning Objectives Section
```markdown
## Learning Objectives {#sec:objectives-XX}

By the end of this chapter, you will be able to:

1. [Action verb] [specific outcome]
2. [Action verb] [specific outcome]
3. [Action verb] [specific outcome]

::: {.callout-think}
**Before we begin:** Think about a time when you encountered [topic] in everyday life. What did you notice?
:::
```

### 3. Introduction with Context
- Start with real-world relevance (automotive, food, defense industries)
- Use storytelling or scenarios
- Connect to previous knowledge
- Pose questions to activate thinking

### 4. Main Content Sections

Each major concept should include:

**Theory/Concept explanation:**
- Clear definitions
- Mathematical formulations using LaTeX
- Cross-referenced equations

**Visual representation:**
- R code chunks generating ggplot2 visualizations
- Cross-referenced figures
- Descriptive captions

**Worked examples:**
- Step-by-step solutions
- Industry-relevant scenarios
- Show calculations explicitly

**Interactive elements:**
- Questions for reflection
- Prompts for discussion
- "Pause and think" moments

### 5. Chapter End Elements
```markdown
## Key Takeaways {#sec:takeaways-XX}

- [Bullet point summary]
- [Bullet point summary]

## Practice Problems {#sec:problems-XX}

1. [Problem statement with industry context]
2. [Problem statement with industry context]

## Further Resources {#sec:resources-XX}

- [Relevant resources]
- [Video links using youtube helper]
```

## Interactive Element Examples

### Discussion Prompts
```markdown
::: {.callout-discussion}
**Group Discussion:** How would you apply [concept] in an automotive assembly line? Consider both benefits and challenges.
:::
```

### Reflection Questions
```markdown
::: {.callout-reflect}
**Think About It:** Before reading on, how do you think [process] affects [outcome]? Write down your hypothesis.
:::
```

### Quick Checks
```markdown
::: {.callout-check}
**Quick Check:** Can you identify three examples of [concept] in a food processing plant?
:::
```

### Hands-On Activities
```markdown
::: {.callout-activity}
**Try This:** Use the R code below to explore how changing [parameter] affects [outcome].
:::
```

### Question and Answer Sections
```markdown
::: {.question}
How does increasing defect rate affect overall equipment effectiveness?
:::

::: {.answer}
Increasing defect rate directly reduces the Quality component of OEE. For example, if defect rate increases from 2% to 5%, the Quality factor drops from 0.98 to 0.95, reducing overall OEE proportionally.
:::
```

## R Code Chunk Patterns

### Data Generation and Visualization
```markdown
```{r fig-process-flow-XX, fig.cap="Description of the visualization", fig.align='center'}
# Generate sample data
set.seed(123)
data <- data.frame(
  category = rep(c("A", "B", "C"), each = 100),
  value = c(rnorm(100, 50, 10), 
            rnorm(100, 60, 12), 
            rnorm(100, 55, 8))
)

# Create visualization
library(ggplot2)
ggplot(data, aes(x = category, y = value, fill = category)) +
  geom_boxplot() +
  labs(
    title = "Process Comparison",
    x = "Process Type",
    y = "Efficiency (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```
```

### Time Series Data
```markdown
```{r fig-trend-analysis-XX, fig.cap="Trend analysis over time", fig.align='center'}
# Generate time series data
library(dplyr)
library(lubridate)

time_data <- data.frame(
  date = seq(as.Date("2023-01-01"), as.Date("2023-12-31"), by = "day"),
  efficiency = 85 + cumsum(rnorm(365, 0, 2))
) %>%
  mutate(efficiency = pmin(pmax(efficiency, 70), 100))

# Visualize trend
ggplot(time_data, aes(x = date, y = efficiency)) +
  geom_line(color = "steelblue", size = 1) +
  geom_smooth(method = "loess", se = TRUE, color = "red", linetype = "dashed") +
  labs(
    title = "Manufacturing Efficiency Over Time",
    x = "Date",
    y = "Efficiency (%)"
  ) +
  theme_minimal()
```
```

### Comparative Bar Charts
```markdown
```{r fig-comparison-XX, fig.cap="Comparison across different methods", fig.align='center'}
# Create comparison data
comparison_data <- data.frame(
  method = c("Traditional", "Lean", "Six Sigma", "Hybrid"),
  cycle_time = c(45, 32, 35, 28),
  defect_rate = c(5.2, 2.1, 1.8, 1.5),
  cost = c(100, 85, 90, 82)
)

# Reshape for grouped bar chart
library(tidyr)
comparison_long <- comparison_data %>%
  pivot_longer(cols = -method, names_to = "metric", values_to = "value")

# Create grouped bar chart
ggplot(comparison_long, aes(x = method, y = value, fill = metric)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~metric, scales = "free_y") +
  labs(
    title = "Method Comparison Across Key Metrics",
    x = "Method",
    y = "Value"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")
```
```

## LaTeX Math Examples

### Inline equations
```markdown
The efficiency can be calculated as $\eta = \frac{P_{out}}{P_{in}} \times 100\%$ where...
```

### Display equations with cross-reference
```markdown
The Overall Equipment Effectiveness (OEE) is calculated as:

\begin{equation}
OEE = Availability \times Performance \times Quality
(\#eq:oee-formula-XX)
\end{equation}

Where each component is expressed as a percentage. See Equation \@ref(eq:oee-formula-XX).
```

### Multi-line equations
```markdown
\begin{align}
Availability &= \frac{Operating\ Time}{Planned\ Production\ Time} (\#eq:availability-XX) \\
Performance &= \frac{Actual\ Output}{Theoretical\ Output} (\#eq:performance-XX) \\
Quality &= \frac{Good\ Units}{Total\ Units} (\#eq:quality-XX)
\end{align}
```

## Cross-Referencing Examples

### Figures
```markdown
As shown in Figure \@ref(fig:process-flow-XX), the relationship between...
```

### Equations
```markdown
Using Equation \@ref(eq:oee-formula-XX), we can calculate...
```

### Sections
```markdown
Refer back to Section \@ref(sec:objectives-XX) for the learning goals.
```

### Tables
```markdown
Table \@ref(tab:comparison-XX) summarizes the key differences...
```

## Industry-Specific Example Topics

### Automotive Industry
- Assembly line efficiency
- Just-in-time inventory
- Quality control in manufacturing
- Ergonomic workstation design
- Defect tracking and reduction

### Food Industry
- Process flow optimization
- Food safety protocols (HACCP)
- Temperature control systems
- Sanitation and cleaning schedules
- Batch tracking and traceability

### Defense Industry
- Precision manufacturing requirements
- Quality assurance procedures
- Supply chain security
- Configuration management
- Compliance and documentation

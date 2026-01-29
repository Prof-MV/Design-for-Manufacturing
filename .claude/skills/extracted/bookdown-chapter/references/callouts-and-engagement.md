# Interactive Callout Boxes and Engagement Elements

## CSS Styling Requirements

For proper rendering of question/answer sections and callout boxes, ensure your bookdown project includes a `styles.css` file with appropriate class definitions. See `references/styles-example.css` for a complete example stylesheet.

The key CSS classes needed are:
- `.question` - For formatting question sections
- `.answer` - For formatting answer sections
- `.callout-*` classes - For various callout box types (think, discussion, check, etc.)

## Callout Box Styles

Bookdown supports various callout styles using div containers with custom CSS classes.

### Think Boxes
**Purpose:** Encourage active reflection before introducing new concepts

```markdown
::: {.callout-think}
**Before You Read:** How do you think temperature affects chemical reaction rates in food processing? Make a prediction.
:::
```

### Discussion Prompts
**Purpose:** Facilitate group learning and peer discussion

```markdown
::: {.callout-discussion}
**Group Discussion:** In teams of 3-4, discuss how lean manufacturing principles could reduce waste in your local automotive plant. List 5 specific opportunities.
:::
```

### Quick Check Questions
**Purpose:** Verify understanding of concepts just learned

```markdown
::: {.callout-check}
**Quick Check:** 
1. What are the three components of OEE?
2. If Availability = 90%, Performance = 95%, and Quality = 98%, what is the OEE?
:::
```

### Warning/Caution Boxes
**Purpose:** Highlight common mistakes or safety concerns

```markdown
::: {.callout-warning}
**Common Mistake:** Students often confuse cycle time with takt time. Remember: cycle time is how long it takes to complete one unit, while takt time is the rate at which you need to produce to meet customer demand.
:::
```

### Industry Connection
**Purpose:** Connect theory to real-world industry applications

```markdown
::: {.callout-industry}
**Industry Application:** In automotive manufacturing, Ford uses this exact approach in their F-150 assembly line to reduce changeover time from 4 hours to 45 minutes.
:::
```

### Try It Yourself
**Purpose:** Hands-on activities with R code

```markdown
::: {.callout-activity}
**Hands-On Activity:** Run the code below and experiment by changing the parameters. What happens to efficiency when you increase the defect rate?
:::
```

### Key Concept Boxes
**Purpose:** Highlight definitions and important concepts

```markdown
::: {.callout-concept}
**Key Concept: Takt Time**  
Takt time is the rate at which products must be completed to meet customer demand. Formula: $Takt\ Time = \frac{Available\ Time}{Customer\ Demand}$
:::
```

### Real-World Example
**Purpose:** Provide concrete industry scenarios

```markdown
::: {.callout-example}
**Real-World Example:** A food processing plant produces 10,000 units per day with an 8-hour shift. Let's calculate their required takt time...
:::
```

### Question and Answer Formatting
**Purpose:** Format questions and answers with consistent styling using styles.css

```markdown
::: {.question}
What is the relationship between cycle time and production capacity?
:::

::: {.answer}
Cycle time directly determines the maximum number of units that can be produced per time period. For example, if cycle time is 60 seconds, the theoretical maximum production rate is 60 units per hour (assuming 100% uptime).
:::
```

**Multiple Q&A pairs:**
```markdown
::: {.question}
Why is takt time important in lean manufacturing?
:::

::: {.answer}
Takt time establishes the production pace needed to meet customer demand. It helps identify whether current cycle times are adequate and highlights areas where improvements are needed.
:::

::: {.question}
How does OEE differ from simple efficiency metrics?
:::

::: {.answer}
OEE provides a comprehensive view by combining availability, performance, and quality into a single metric. Unlike simple efficiency measures, OEE accounts for all types of production losses including downtime, speed losses, and quality defects.
:::
```

## Engagement Strategies for Lectures

### Opening Hook Questions
Start each major section with a question:

```markdown
## Introduction to Process Flow

Have you ever wondered why some assembly lines move smoothly while others seem chaotic? Today we'll discover the science behind efficient process flow.
```

### Predict-Observe-Explain Pattern
```markdown
### Understanding Machine Efficiency

**Predict:** Before we look at the data, what do you think happens to machine efficiency as it ages?

[Show visualization]

**Observe:** What patterns do you notice in Figure \@ref(fig:efficiency-decline)?

**Explain:** The data shows... This happens because...
```

### Pause Points
Insert strategic pauses for reflection:

```markdown
::: {.callout-pause}
**Pause and Reflect:** Take 2 minutes to write down three ways you could apply this concept in a manufacturing setting you're familiar with.
:::
```

### Connect to Prior Knowledge
```markdown
::: {.callout-recall}
**Remember from Chapter X:** We learned that standard deviation measures variability. Now we'll see how this applies to process control.
:::
```

### Challenge Questions
```markdown
::: {.callout-challenge}
**Challenge Problem:** For students wanting to go deeper: How would you optimize a multi-stage process where each stage has different bottleneck constraints?
:::
```

## Interactive R Code Patterns

### Slider-Style Exploration (using comments)
```markdown
```{r fig-parameter-exploration, fig.cap="Explore how parameters affect outcomes"}
# Try changing these values and re-running the code:
defect_rate <- 0.05  # Try values between 0.01 and 0.20
production_rate <- 100  # Try values between 50 and 200
efficiency_factor <- 0.95  # Try values between 0.80 and 1.00

# Simulate production data
set.seed(42)
production_data <- data.frame(
  hour = 1:24,
  output = rpois(24, production_rate * efficiency_factor * (1 - defect_rate))
)

# Visualize results
ggplot(production_data, aes(x = hour, y = output)) +
  geom_line(color = "darkblue", size = 1.2) +
  geom_point(color = "darkred", size = 3) +
  geom_hline(yintercept = production_rate * efficiency_factor * (1 - defect_rate), 
             linetype = "dashed", color = "gray50") +
  labs(
    title = "Hourly Production Output",
    subtitle = paste("Defect Rate:", defect_rate, "| Expected Output:", 
                     round(production_rate * efficiency_factor * (1 - defect_rate))),
    x = "Hour",
    y = "Units Produced"
  ) +
  theme_minimal()
```
:::
```

### Before and After Comparisons
```markdown
```{r fig-before-after, fig.cap="Impact of process improvement"}
library(patchwork)

# Before improvement
before_data <- data.frame(
  time = 1:50,
  efficiency = rnorm(50, 75, 8)
)

# After improvement
after_data <- data.frame(
  time = 1:50,
  efficiency = rnorm(50, 88, 5)
)

# Create side-by-side plots
p1 <- ggplot(before_data, aes(x = time, y = efficiency)) +
  geom_line(color = "red") +
  ylim(50, 100) +
  labs(title = "Before Lean Implementation", y = "Efficiency (%)") +
  theme_minimal()

p2 <- ggplot(after_data, aes(x = time, y = efficiency)) +
  geom_line(color = "green") +
  ylim(50, 100) +
  labs(title = "After Lean Implementation", y = "Efficiency (%)") +
  theme_minimal()

# Combine plots
p1 + p2
```

::: {.callout-discussion}
**Discuss:** What specific changes do you think were made to achieve this improvement?
:::
```

### Interactive Annotations
```markdown
```{r fig-annotated-process, fig.cap="Annotated process diagram with key decision points"}
# Create process flow data
process_steps <- data.frame(
  step = 1:5,
  time = c(10, 15, 8, 12, 20),
  step_name = c("Receiving", "Inspection", "Processing", "Assembly", "Packaging")
)

ggplot(process_steps, aes(x = step, y = time)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = step_name), vjust = -0.5, size = 3.5) +
  geom_text(aes(label = paste(time, "min")), vjust = 1.5, color = "white", 
            fontface = "bold") +
  # Annotate bottleneck
  annotate("segment", x = 5, xend = 5, y = 22, yend = 25, 
           arrow = arrow(length = unit(0.3, "cm")), color = "red", size = 1) +
  annotate("text", x = 5, y = 26, label = "BOTTLENECK", 
           color = "red", fontface = "bold") +
  labs(
    title = "Process Step Times",
    x = "Process Step",
    y = "Time (minutes)"
  ) +
  theme_minimal()
```

::: {.callout-think}
**Analysis Question:** Which step should we focus on improving first? Why?
:::
```

## Video Integration Pattern

```markdown
::: {.callout-video}
**Watch:** This 5-minute video explains the concept visually

`r include_youtube("VIDEO_ID")`

**After watching:** How does this relate to what we learned about [previous concept]?
:::
```

## End-of-Section Review Pattern

```markdown
## Section Summary {#sec:summary-section-name}

::: {.callout-summary}
**What We Learned:**
- [Key point 1]
- [Key point 2]
- [Key point 3]

**Key Equations:**
- [Equation reference with number]
- [Equation reference with number]

**Before Moving On:**
- Can you explain [concept] to a classmate?
- Can you calculate [metric] given [parameters]?
- Can you identify where [concept] applies in your workplace?
:::
```

## Problem-Based Learning Format

```markdown
## Case Study: Optimizing Automotive Assembly Line {#sec:case-automotive}

::: {.callout-case}
**The Situation:**  
ABC Automotive manufactures SUV door panels. Their current process has:
- 8-hour shifts, 5 days/week
- Customer demand: 480 units/day
- Current cycle time: 95 seconds/unit
- Defect rate: 3.5%

**Your Challenge:**  
Work through the following questions to analyze and improve this process.
:::

### Step 1: Calculate Takt Time

::: {.callout-think}
**Before you calculate:** Will they be able to meet customer demand with their current cycle time? Make a prediction.
:::

[Provide calculation guidance and solution]

### Step 2: Identify the Problem

[Continue with structured problem-solving]
```

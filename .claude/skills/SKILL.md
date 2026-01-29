---
name: bookdown-chapter
description: Write comprehensive bookdown chapters for undergraduate engineering textbooks that double as lecture notes. Use when creating new chapters for process engineering topics (plant layout, PFMEA, lean manufacturing, ergonomics, etc.) targeting second-year electromechanical/mechanical students preparing for automotive, food, and defense industries. Generates complete R markdown with interactive elements, R code chunks with ggplot2 visualizations, LaTeX equations, cross-references, and engagement strategies for teaching.
---

# Bookdown Engineering Chapter Writer

Write comprehensive, engaging bookdown chapters for undergraduate engineering students that serve as both textbook content and lecture notes.

## Target Audience

- **Level:** Second-year undergraduate students (electromechanical/mechanical programs)
- **Future careers:** Automotive, food processing, and defense industries
- **Learning style:** Hands-on, practical, industry-connected
- **Teaching context:** Chapters are used in live lectures and as self-study material

## Chapter Structure

Create each chapter with this structure:

### 1. Header and Setup Block
```markdown
# [Descriptive Chapter Title] {#chap-XX-topic}

```{r setup-XX, include=FALSE}
# include the helpers.R file for pdf output of youtube on pdfs as a clickable link
source("R/helpers.R")
# include the required packages to make sure the page can be built.
source("R/required_packages.R")
```
```

### 2. Learning Objectives
Start with clear, measurable learning objectives using action verbs (analyze, calculate, design, evaluate, implement).

### 3. Introduction with Hook
Begin with:
- Real-world scenario or question
- Industry connection (automotive, food, or defense)
- Bridge from prior knowledge
- Engagement question to activate thinking

### 4. Main Content Sections
For each major concept, include:

**Theory/Explanation:**
- Clear definitions in plain language
- LaTeX equations for mathematical relationships
- Cross-referenced equation numbers

**Visualization:**
- R code chunks generating complete, runnable visualizations
- ggplot2 or other appropriate R packages
- Simulated data when real data unavailable
- Cross-referenced figure numbers
- Descriptive figure captions

**Worked Examples:**
- Industry-specific scenarios
- Step-by-step solutions showing all work
- Explicit calculations
- Units clearly labeled

**Interactive Elements:**
- Think boxes (before concepts)
- Discussion prompts (for group work)
- Quick check questions (after concepts)
- Hands-on activities with R code
- Pause and reflect moments

### 5. End-of-Chapter Elements
- Key takeaways summary
- Practice problems with industry context
- Further resources or video links

## R Code Chunk Requirements

All R code chunks MUST:

1. **Be complete and runnable** - No placeholder data or incomplete code
2. **Generate data** - Create simulated data using reproducible seeds when needed
3. **Use proper cross-referencing** - Label chunks for figure references (e.g., `fig-topic-XX`)
4. **Include descriptive captions** - Use `fig.cap` parameter
5. **Use appropriate packages** - Primarily ggplot2, dplyr, tidyr
6. **Follow clean coding practices** - Comments, readable variable names
7. **Set appropriate figure options** - `fig.align='center'` and appropriate sizing

Example pattern:
```markdown
```{r fig-efficiency-comparison-05, fig.cap="Comparison of manufacturing efficiency across different methods", fig.align='center'}
# Generate comparison data
set.seed(123)
efficiency_data <- data.frame(
  method = rep(c("Traditional", "Lean", "Six Sigma"), each = 50),
  efficiency = c(
    rnorm(50, 75, 8),
    rnorm(50, 88, 6),
    rnorm(50, 92, 5)
  )
)

# Create visualization
library(ggplot2)
ggplot(efficiency_data, aes(x = method, y = efficiency, fill = method)) +
  geom_boxplot() +
  labs(
    title = "Manufacturing Efficiency by Method",
    x = "Method",
    y = "Efficiency (%)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
```
```

## LaTeX Math Formatting

**Inline equations:** Use single dollar signs for inline math: `$\eta = \frac{P_{out}}{P_{in}}$`

**Display equations with cross-reference:**
```markdown
\begin{equation}
OEE = Availability \times Performance \times Quality
(\#eq:oee-XX)
\end{equation}

As shown in Equation \@ref(eq:oee-XX), the Overall Equipment Effectiveness...
```

**Multi-line equations:**
```markdown
\begin{align}
Availability &= \frac{Operating\ Time}{Planned\ Time} (\#eq:avail-XX) \\
Performance &= \frac{Actual\ Output}{Theoretical\ Output} (\#eq:perf-XX)
\end{align}
```

## Cross-Referencing

Use bookdown cross-referencing syntax:

- **Figures:** `Figure \@ref(fig:label-XX)`
- **Equations:** `Equation \@ref(eq:label-XX)`
- **Sections:** `Section \@ref(sec:label-XX)` or `Chapter \@ref(chap-XX)`
- **Tables:** `Table \@ref(tab:label-XX)`

All headers, figures, tables, and equations must have unique labels and be properly cross-referenced in the text.

## Interactive Elements

Incorporate diverse engagement strategies:

**Think Boxes:** Before introducing concepts
```markdown
::: {.callout-think}
**Before You Read:** How do you think [concept] works in practice?
:::
```

**Discussion Prompts:** For group learning
```markdown
::: {.callout-discussion}
**Group Discussion:** In teams, identify 3 ways [concept] applies in your industry of interest.
:::
```

**Quick Checks:** After key concepts
```markdown
::: {.callout-check}
**Quick Check:** Can you explain [concept] in your own words?
:::
```

**Industry Applications:** Connect to real-world
```markdown
::: {.callout-industry}
**Industry Application:** Ford Motor Company uses this approach to reduce changeover times in their F-150 assembly.
:::
```

**Hands-On Activities:** With R code experimentation
```markdown
::: {.callout-activity}
**Try This:** Modify the code above by changing [parameter] and observe what happens.
:::
```

**Questions and Answers:** Use CSS classes for formatted Q&A sections
```markdown
::: {.question}
How does cycle time relate to production capacity?
:::

::: {.answer}
Cycle time directly determines the maximum number of units that can be produced per time period. If cycle time is 60 seconds, the theoretical maximum is 60 units per hour.
:::
```

See `references/callouts-and-engagement.md` for complete list of callout types and engagement patterns.

## Writing Style Guidelines

1. **Conversational but professional** - Write as if teaching in a lecture
2. **Use questions frequently** - Engage students in active thinking
3. **Connect to industry** - Reference automotive, food, and defense applications
4. **Show, don't just tell** - Use visualizations and examples liberally
5. **Build progressively** - Start simple, add complexity gradually
6. **Make math accessible** - Explain equations before and after presenting them
7. **Encourage experimentation** - Invite students to modify R code and explore
8. **No emojis in headers** - Headers should be professional and text-only; emojis can be used in callout boxes and body text when appropriate for engagement

## Industry Context Integration

For each major concept, include at least one concrete example from:

- **Automotive:** Assembly lines, just-in-time inventory, quality control, ergonomics
- **Food processing:** Flow optimization, HACCP, temperature control, sanitation, traceability
- **Defense:** Precision manufacturing, quality assurance, supply chain security, compliance

## Additional Resources

- **Chapter patterns:** See `references/chapter-patterns.md` for detailed structure examples, R code patterns, and industry-specific examples
- **Engagement strategies:** See `references/callouts-and-engagement.md` for callout box styles, interactive elements, and problem-based learning formats
- **CSS Styling:** Ensure your bookdown project includes `styles.css` with definitions for `.question` and `.answer` classes for proper Q&A formatting. These classes should provide visual distinction and consistent styling throughout the book.

## Quality Checklist

Before completing a chapter, verify:

- [ ] Chapter has proper setup chunk with helpers.R and required_packages.R
- [ ] Learning objectives are clear and measurable
- [ ] All headers have unique labels for cross-referencing and contain no emojis
- [ ] All figures have labels, captions, and are referenced in text
- [ ] All equations have labels and are referenced in text
- [ ] R code chunks are complete and runnable with data generation
- [ ] Multiple types of interactive elements are included (think boxes, discussions, quick checks)
- [ ] Question and answer sections use CSS classes (.question and .answer) for proper formatting
- [ ] Industry connections are made to automotive, food, or defense sectors
- [ ] Math is properly formatted in LaTeX
- [ ] Content progresses logically from simple to complex
- [ ] Practice problems are included at chapter end
- [ ] Tone is engaging and conversational for undergraduate audience

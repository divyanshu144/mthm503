# mthm503

This is a template for course MTHM503 "Applications of Data Science and Statistics".  You should fork this repository and use it for your work on this module

Note: in a professional setting, a DevOps engineer (or team of engineers) would be responsible for setting up infrastructure like this. You only have to operate within the infrastructure.  Therefore, you may find yourself working as follows:

1. Develop a script to perform some analysis task.
2. When you are happy with it, wrap it in a function and save it in the functions.R file.
3. You call this function from the _targets.R file in the form 
  tar_target(NAME OF THE OUTPUT, FUNCTION CALL(DATA AND OTHER ARGUMENTS))
4. Run tar_make() in the parent folder. 



⸻

title: “MTHM503 Coursework Report”
author: “Divyanshu Charak”
date: “r Sys.Date()”
output:
html_document:
toc: true
toc_depth: 2
toc_float: true
number_sections: true
theme: flatly
code_folding: hide
df_print: paged
highlight: tango

Project Overview

This project is submitted as part of the MTHM503 module “Applications of Data Science and Statistics”. It comprises three analytical tasks:
	•	Task 1: Supervised classification of pedestrian injury severity
	•	Task 2: Regression analysis on extrication counts in road collisions
	•	Task 3: Unsupervised clustering of olive oil samples

All analyses are implemented using a reproducible pipeline built with {targets} and {renv}.

Workflow Infrastructure

This coursework follows a modern, production-ready R workflow:
	•	📦 Package Management: Uses {renv} to ensure reproducible dependency environments.
	•	🎯 Workflow Pipeline: Implements a modular pipeline using {targets}.
	•	🧪 Testing: Key functions tested using {testthat}.
	•	🔁 Automation: Supports local runs using the run script and CI-ready structure.
	•	🧹 Linting: Code formatting is checked via lintr.
	•	📂 Version Control: GitHub is used to manage commits, branches, and track changes.

Setup Instructions
	1.	Clone this repo: git clone <your-fork-url>
	2.	Open in RStudio.
	3.	Run source("init.R") to set up environment.
	4.	Run targets::tar_make() to build the pipeline.
	5.	Render the report using rmarkdown::render("vignettes/Report.Rmd") or tar_make().

Pipeline Structure

graph TD
  A[Load Raw Data] --> B[Preprocess & Join Tables]
  B --> C1[Task 1: Supervised Classification]
  B --> C2[Task 2: Regression Modelling]
  B --> C3[Task 3: Clustering Olive Oil Data]
  C1 --> D1[Train RF and SVM Models]
  C1 --> D2[Model Evaluation & ROC]
  C2 --> D3[Fit Poisson and NB Models]
  C3 --> D4[PCA + K-Means + Silhouette]

Folder Structure

📁 R/                    # All functions
📁 data/                 # Input data files
📁 vignettes/Report.Rmd  # Final rendered report
📁 tests/                # Unit tests with testthat
📁 _targets.R            # Pipeline configuration
📁 run                   # Shell script for reproducible builds

Declaration

I declare that the work submitted here is entirely my own. I have not used any AI-generated output in the submission unless explicitly allowed or acknowledged. All data analysis and writing were done by me.

⸻

For any technical issues or setup troubleshooting, please refer to the original course instructions or contact the module instructors.




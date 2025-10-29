# ui.R - Interfaccia utente con About page e GitHub link

library(shiny)
library(DT)

ui <- navbarPage(
  title = "Word Predictor",
  
  # CSS personalizzato con cache-buster  
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css?v=20251028-1630"),
    tags$script(src = "custom.js?v=20251028-1630"),
    tags$style(HTML("
      .jumbotron {
        background: linear-gradient(135deg, #0a0a0f 0%, #1a1a2e 50%, #16213e 100%);
        color: #e0e0e0;
        border: 2px solid #00ff88;
        border-radius: 8px;
        margin-bottom: 30px;
        text-align: center;
        padding: 40px;
        box-shadow: 0 0 30px rgba(0, 255, 136, 0.3);
        position: relative;
        overflow: hidden;
      }
      .jumbotron::before {
        content: '';
        position: absolute;
        top: 0;
        left: -100%;
        width: 100%;
        height: 100%;
        background: linear-gradient(90deg, transparent, rgba(0, 255, 136, 0.1), transparent);
        animation: shimmer 3s infinite;
      }
      @keyframes shimmer {
        0% { left: -100%; }
        100% { left: 100%; }
      }
      .jumbotron h1 {
        font-family: 'Orbitron', monospace;
        font-weight: 900;
        color: #00ff88;
        text-shadow: 0 0 20px #00ff88;
        margin-bottom: 20px;
      }
      .algo-tag {
        display: inline-block;
        padding: 8px 16px;
        margin: 5px;
        border-radius: 4px;
        font-size: 0.9em;
        font-weight: 600;
        font-family: 'JetBrains Mono', monospace;
        color: #0a0a0f;
        background: linear-gradient(45deg, #00ff88, #00d4ff);
        border: 1px solid #00ff88;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        box-shadow: 0 0 10px rgba(0, 255, 136, 0.5);
      }
      .algo-card {
        background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
        border-radius: 8px;
        padding: 30px;
        margin: 20px 0;
        box-shadow: 0 0 20px rgba(0, 255, 136, 0.2);
        border: 1px solid #00ff88;
        border-left: 4px solid #00ff88;
        transition: all 0.3s ease;
        color: #e0e0e0;
      }
      .algo-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 0 30px rgba(0, 255, 136, 0.4);
      }
      .algo-card h3 {
        color: #00ff88;
        font-family: 'Orbitron', monospace;
        text-shadow: 0 0 10px #00ff88;
      }
      .github-link {
        color: #00d4ff;
        text-decoration: none;
        font-size: 1.2em;
        font-family: 'JetBrains Mono', monospace;
        transition: all 0.3s ease;
      }
      .github-link:hover {
        color: #00ff88;
        text-shadow: 0 0 8px #00ff88;
      }
    "))
  ),
  
  # TAB 1: PREDICT
  tabPanel("📝 Predict",
    # Header per la tab predict
    div(class = "jumbotron",
      h1("Word Predictor"),
      p("N-gram Language Model", style = "color: white;"),
      div(
        span(class = "algo-tag", "🎯 Stupid Backoff"),
        span(class = "algo-tag", "🧮 Interpolated + IDF"),
        span(class = "algo-tag", "📦 Rcaptext Package")
      )
    ),
  
  # Layout principale
  sidebarLayout(
    # Pannello di controllo semplice
    sidebarPanel(
      width = 4,
      
      h4("🎯 Input & Settings"),
      
      # Input di testo
      textInput("input_text", 
               "Enter your text:", 
               value = "I would like to",
               placeholder = "Type your text here..."),
      
      # Scelta algoritmo
      radioButtons("method", "Algorithm:",
                  choices = list(
                    "🎯 Stupid Backoff" = "backoff",
                    "🧮 Interpolated + IDF" = "interpolated"
                  ),
                  selected = "backoff"),
      
      # Numero di predizioni
      sliderInput("top_k", "Number of predictions:", 
                 min = 1, max = 10, value = 5, step = 1),
      
      # Parametri per Stupid Backoff
      conditionalPanel(
        condition = "input.method == 'backoff'",
        sliderInput("alpha", "Alpha (α):", 
                   min = 0.1, max = 1.0, value = 0.4, step = 0.1)
      ),
      
      # Parametri per Interpolated
      conditionalPanel(
        condition = "input.method == 'interpolated'",
        sliderInput("lambda_tri", "Trigram weight:", 
                   min = 0, max = 1, value = 0.7, step = 0.05),
        sliderInput("lambda_bi", "Bigram weight:", 
                   min = 0, max = 1, value = 0.2, step = 0.05),
        textOutput("lambda_uni_display"),
        br(),
        sliderInput("beta", "IDF boost:", 
                   min = 0, max = 2, value = 0.3, step = 0.1)
      ),
      
      br(),
      
      # Pulsante predizione
      actionButton("predict_btn", "🚀 Predict", 
                  class = "btn-primary btn-lg btn-block"),
      
      br(),
      
      # Theme Toggle Button
      actionButton("dark-mode-toggle", "🌌 Cyber Mode", 
                  class = "btn btn-secondary btn-sm btn-block",
                  style = "margin-top: 10px;"),
      
      br(),
      
      # Status
      div(class = "well",
          h5("⚡ Performance Status"),
          textOutput("status_text"),
          textOutput("timing_text")
      )
    ),
    
    # Pannello risultati
    mainPanel(
      width = 8,
      
      # Info rapide
      div(class = "info-card",
        h4("🎯 Prediction Results"),
        fluidRow(
          column(4,
            div(class = "text-center",
              h6("📦 Package"),
              span(class = "algo-tag", "Rcaptext")
            )
          ),
          column(4,
            div(class = "text-center",
              h6("🧠 Model Size"),
              span(class = "algo-tag", "744K n-grams")
            )
          ),
          column(4,
            div(class = "text-center",
              h6("⚡ Status"),
              span(class = "algo-tag", "Ready")
            )
          )
        )
      ),
      
      # Tabella risultati
      div(class = "info-card",
        DT::dataTableOutput("predictions_table")
      ),
      
      br(),
      
      # Info dettagliate
      fluidRow(
        column(6,
          div(class = "info-card",
            h5("📊 Algorithm Info"),
            verbatimTextOutput("algorithm_info")
          )
        ),
        column(6,
          div(class = "info-card",
            h5("🔍 Input Analysis"),
            verbatimTextOutput("input_analysis")
          )
        )
      )
    )
  )
  ), # Fine TAB 1: PREDICT
  
  # TAB 2: ABOUT
  tabPanel("📚 About",
    div(class = "container-fluid",
      div(class = "jumbotron",
        h1("📚 About Word Predictor"),
        p("Learn about the algorithms and technology behind this application", style = "color: white;")
      ),
      
      # Sezione Algoritmi
      div(class = "algo-card",
        h3("🎯 Stupid Backoff Algorithm"),
        p("The Stupid Backoff algorithm is a simplified version of the Katz backoff model. It provides efficient n-gram language modeling without requiring smoothing parameters."),
        h5("How it works:"),
        tags$ul(
          tags$li("First tries to find the complete n-gram (trigram) in the model"),
          tags$li("If not found, backs off to (n-1)-gram (bigram) with penalty α"),
          tags$li("Continues backing off to unigrams if needed"),
          tags$li("Fast and memory-efficient for large datasets")
        ),
        h5("Parameters:"),
        tags$ul(
          tags$li(strong("α (Alpha):"), " Backoff penalty weight (default: 0.4)")
        )
      ),
      
      div(class = "algo-card",
        h3("🧮 Interpolated + IDF Algorithm"),
        p("This advanced algorithm combines linear interpolation of n-gram probabilities with Inverse Document Frequency (IDF) reranking for improved prediction quality."),
        h5("How it works:"),
        tags$ul(
          tags$li("Calculates probabilities for trigrams, bigrams, and unigrams"),
          tags$li("Combines them using weighted linear interpolation: λ₃×P₃ + λ₂×P₂ + λ₁×P₁"),
          tags$li("Applies IDF boosting to favor less common but more informative words"),
          tags$li("Provides more nuanced predictions than simple backoff")
        ),
        h5("Parameters:"),
        tags$ul(
          tags$li(strong("λ₃ (Lambda Trigram):"), " Weight for trigram probability (default: 0.7)"),
          tags$li(strong("λ₂ (Lambda Bigram):"), " Weight for bigram probability (default: 0.2)"),
          tags$li(strong("λ₁ (Lambda Unigram):"), " Weight for unigram probability (auto-calculated)"),
          tags$li(strong("β (Beta):"), " IDF boost factor (default: 0.3)")
        )
      ),
      
      # Sezione Tecnologia
      div(class = "algo-card",
        h3("📦 Technology Stack"),
        fluidRow(
          column(6,
            h5("🔧 Core Components:"),
            tags$ul(
              tags$li(strong("R Language:"), " Statistical computing and modeling"),
              tags$li(strong("Shiny Framework:"), " Interactive web application"),
              tags$li(strong("Rcaptext Package:"), " Custom n-gram prediction engine"),
              tags$li(strong("DT Package:"), " Interactive data tables")
            )
          ),
          column(6,
            h5("📊 Model Statistics:"),
            tags$ul(
              tags$li(strong("52,718"), " unique unigrams"),
              tags$li(strong("183,284"), " unique bigrams"),
              tags$li(strong("508,003"), " unique trigrams"),
              tags$li(strong("< 50ms"), " average prediction time")
            )
          )
        )
      ),
      
      # Sezione Performance
      div(class = "algo-card",
        h3("⚡ Performance Features"),
        fluidRow(
          column(4,
            h5("🚀 Speed Optimizations:"),
            tags$ul(
              tags$li("Pre-computed n-gram lookup tables"),
              tags$li("Vectorized probability calculations"),
              tags$li("Efficient memory management"),
              tags$li("Optimized data structures (RDS format)")
            )
          ),
          column(4,
            h5("🧠 Smart Features:"),
            tags$ul(
              tags$li("Case-insensitive input handling"),
              tags$li("Automatic text cleaning"),
              tags$li("Context-aware predictions"),
              tags$li("Multiple algorithm comparison")
            )
          ),
          column(4,
            h5("🎯 User Experience:"),
            tags$ul(
              tags$li("Real-time parameter adjustment"),
              tags$li("Interactive results table"),
              tags$li("Performance timing display"),
              tags$li("Responsive design")
            )
          )
        )
      )
    )
  ),
  
  # TAB 3: INFO & CONTACT
  tabPanel("ℹ️ Info",
    div(class = "container-fluid",
      div(class = "jumbotron",
        h1("ℹ️ Project Information"),
        p("Model statistics and performance metrics", style = "color: white;")
      ),
      
      # Statistics
      div(class = "algo-card",
        h3("📊 Model Statistics"),
        fluidRow(
          column(4,
            div(class = "text-center",
              h2("52,718", style = "color: #667eea; margin: 0;"),
              p("Unigrams")
            )
          ),
          column(4,
            div(class = "text-center",
              h2("183,284", style = "color: #667eea; margin: 0;"),
              p("Bigrams")
            )
          ),
          column(4,
            div(class = "text-center",
              h2("508,003", style = "color: #667eea; margin: 0;"),
              p("Trigrams")
            )
          )
        ),
        hr(),
        div(class = "text-center",
          h4("⚡ Performance: < 50ms average prediction time"),
          h4("💾 Total model size: 744,005 n-grams")
        )
      ),
      
      # Algorithm Performance Charts
      div(class = "algo-card", style = "margin-top: 30px;",
        h3("📈 Algorithm Performance Analysis"),
        fluidRow(
          column(6,
            div(class = "text-center",
              h4("🎯 Katz Backoff Algorithm", style = "color: steelblue;"),
              tags$img(src = "plot_accuracy_at_k_long.png", 
                      width = "100%", style = "max-width: 350px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"),
              br(), br(),
              tags$small("Fast and reliable predictions using statistical backoff", 
                        style = "color: #666;")
            )
          ),
          column(6,
            div(class = "text-center",
              h4("🧠 Linear Interpolation", style = "color: darkblue;"),
              tags$img(src = "plot_accuracy_at_k_interpolation.png", 
                      width = "100%", style = "max-width: 350px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"),
              br(), br(),
              tags$small("Higher accuracy through weighted n-gram combination", 
                        style = "color: #666;")
            )
          )
        ),
        hr(),
        div(class = "text-center",
          h4("⚖️ Head-to-Head Comparison", style = "color: #333; margin-bottom: 20px;"),
          tags$img(src = "plot_algorithm_comparison.png", 
                  width = "100%", style = "max-width: 500px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"),
          br(), br(),
          tags$small("Both algorithms evaluated on identical test data (10,000 cases)", 
                    style = "color: #666;")
        )
      ),
      
      # Footer con GitHub links
      div(class = "info-card", style = "text-align: center; margin-top: 30px;",
        hr(),
        div(style = "margin: 20px 0;",
          a(href = "https://github.com/Kernel236", target = "_blank", class = "github-link",
            style = "font-size: 1.3em; margin-right: 20px;",
            icon("github"), " GitHub Profile"
          ),
          a(href = "https://github.com/Kernel236/word-predictor", target = "_blank", 
            class = "btn btn-primary btn-sm",
            style = "margin-left: 15px;",
            icon("code"), " View Source"
          )
        ),
        p(style = "margin: 10px 0; color: #666;",
          "© 2025 Word Predictor | Advanced N-gram Language Modeling"
        )
      )
    )  
  )
)

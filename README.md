# 📘 Finanzas_Internacionales_UBA_2025  
**Crecimiento y Aceleración del Crédito Bancario como Predictores de Crisis Bancarias**  
Maestría en Economía Aplicada – UBA  
Autor: **Julián Delgadillo Marín**  
Año: **2025**

---

## 📄 Descripción del estudio

Este repositorio contiene el código, datos, figuras y el informe final del trabajo:

**“Crecimiento y Aceleración del Crédito Bancario como Predictors de Crisis Bancarias Sistémicas”**  
:contentReference[oaicite:1]{index=1}

El estudio analiza si el **crecimiento del crédito** y, especialmente, su **aceleración** (segunda diferencia) anticipan la probabilidad de ocurrencia de **crisis bancarias sistémicas**. Se utilizan datos del BIS, Banco Mundial, IMF Global Macro Database y la base de crisis de Laeven & Valencia (2020).  

El informe replica un enfoque de *early warning indicators* ampliamente utilizado por el BIS y literatura macroprudencial.

---

## 🎯 Objetivo

Evaluar si:

- **Δ Crédito (crecimiento interanual)**
- **Δ² Crédito (aceleración)**  

incrementan la probabilidad de crisis bancaria, mediante modelos de regresión Logit, Probit, FE/RE, y curvas ROC fuera de muestra.

---

## 🧠 Principales resultados (síntesis ejecutiva)

Según el análisis econométrico del informe:

### ✔ Hallazgos clave
- Tanto el **crecimiento** como la **aceleración** del crédito son predictores significativos de crisis bancarias.
- La **aceleración** del crédito es un **indicador más informativo** que el crecimiento simple.
- El modelo predictivo logra un **AUROC = 0.81** (Figura 10, pág. 5), indicando buen poder discriminante.
- Los efectos marginales muestran que:
  - +1 p.p. en crecimiento → **+0.025 p.p.** de probabilidad de crisis.
  - +1 p.p. en aceleración → **−0.057 p.p.** de probabilidad de crisis.

### ✔ Robustez
- Resultados estables con rezagos t−1 y t−2.
- Resultados consistentes en Logit, Probit, FE y RE.
- Test de Hausman favorece RE en la muestra.

---

## 📂 Estructura del repositorio

Finanzas_Internacionales_UBA_2025/
│
├── README.md → Descripción del proyecto
├── LICENSE → MIT License
├── .gitignore → Ignora logs, SMCL, gph, temporales, etc.
│
├── TrabajoFinal_FinanzasInternacionales.pdf → Informe completo
│
├── /src → Código Stata (do-files)
│ ├── do_master.do
│ ├── limpieza_panel.do
│ ├── modelos_logit.do
│ ├── graficos.do
│
├── /data → Datos utilizados
│ ├── bis_credit.csv
│ ├── crisis_laeven_valencia.csv
│ ├── controles_macro.csv
│ └── panel_final.dta
│
└── /figures → Gráficos generados (Fig. 1–10)
├── fig1_credito_panel.png
├── fig2_latam.png
├── fig_roc.png
└── ...

---

---

## 🔧 Reproducibilidad: ¿Qué ejecuta el script maestro?

El archivo principal `do_master.do` automatiza todo el flujo de trabajo del proyecto:

1. **Carga y limpieza del panel consolidado**  
   - Unifica BIS, Laeven & Valencia, WDI/IMF GMD  
   - Armoniza códigos ISO3 y años  
   - Depura datos faltantes y outliers

2. **Construcción de las métricas crediticias**  
   - Δ Crédito (crecimiento interanual)  
   - Δ² Crédito (aceleración, segunda diferencia)

3. **Estimaciones econométricas principales**  
   - Modelos Logit (pooled, FE, con clustering)  
   - Modelos Probit agrupados  
   - Efectos fijos (FE) y efectos aleatorios (RE)  
   - Test de Hausman para FE vs RE  
   - Robustez temporal (t−1 y t−2)

4. **Curva ROC fuera de muestra**  
   - Evaluación predictiva (AUROC)  
   - Validación sobre período 2006–2023

5. **Efectos marginales (AME)**  
   - Interpretación económica del impacto marginal  
   - Modelos Logit y Probit

6. **Exportación automática**  
   - Tablas de regresión  
   - Figuras  
   - Panel final en `/data`  
   - Resultados gráficos en `/figures`

---

## 📈 Visualizaciones incluidas

El informe y el repositorio generan las siguientes figuras:

- **Fig. 1–2:** Evolución del crédito privado (% PIB)  
- **Fig. 3:** Crecimiento vs. aceleración del crédito  
- **Fig. 4–5:** Distribuciones del crecimiento y aceleración  
- **Fig. 6–8:** Crédito antes, durante y después de crisis  
- **Fig. 9:** Cronología de crisis bancarias (1976–2008)  
- **Fig. 10:** Curva ROC – AUROC = **0.81**  

Todas las visualizaciones están disponibles en la carpeta:


---

## 📚 Bibliografía base

- Borio, C.; Drehmann, M.; Tsatsaronis, K. (2014, 2018)  
- Drehmann, M. & Juselius, M. (2014)  
- Schularick, M. & Taylor, A. (2012)  
- Laeven, L. & Valencia, F. (2020)  
- IMF Global Macro Database (2024)  
- BIS Credit Statistics (2024)

---

## 📝 Licencia

Este repositorio utiliza la **MIT License**, permitiendo:

- Uso académico  
- Reutilización del código  
- Distribución y adaptación sin restricciones  

El archivo `LICENSE` en este repositorio contiene los detalles.

---

## 📬 Contacto

Para comentarios, discusión o propuestas de extensión del análisis:

**Julián Delgadillo Marín**  
Maestría en Economía Aplicada – UBA  
GitHub: https://github.com/delgjulian

---

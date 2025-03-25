#!/bin/bash

OUTPUT_DIR="./relatorios_dns"
mkdir -p "$OUTPUT_DIR"

# Obtém a lista de todos os projetos no Google Cloud
projects=$(gcloud projects list --format="value(projectId)")

for PROJECTID in $projects; do
    echo "🔍 Verificando projeto: $PROJECTID"
    
    # Obtém a lista de zonas gerenciadas no projeto
    zones=$(gcloud dns managed-zones list --project="$PROJECTID" --format="value(name)")
    
    REPORT_FILE="$OUTPUT_DIR/relatorio_${PROJECTID}.txt"
    
    if [[ -n "$zones" ]]; then
        echo "📌 Projeto: $PROJECTID" > "$REPORT_FILE"
        echo "==============================" >> "$REPORT_FILE"
        
        for zone in $zones; do
            echo " Zona Gerenciada: $zone" >> "$REPORT_FILE"
            gcloud dns record-sets list --zone="$zone" --project="$PROJECTID" >> "$REPORT_FILE"
            echo "------------------------" >> "$REPORT_FILE"
        done

        echo " Relatório gerado para $PROJECTID: $REPORT_FILE"
    else
        echo "Nenhuma zona encontrada para o projeto $PROJECTID"
    fi
done

echo "Relatórios gerados na pasta: $OUTPUT_DIR"

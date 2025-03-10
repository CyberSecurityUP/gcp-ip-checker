#!/bin/bash

# Solicita o ID da organização antes de iniciar o menu
read -p "🔹 Digite o ID da organização do GCP: " ORG_ID

# Nome dos arquivos de saída
OUTPUT_FILE="output.csv"
COMPARE_OUTPUT="comparison_result.csv"
DETAILED_OUTPUT_CSV="output_detalhado.csv"
DETAILED_OUTPUT_TXT="output_detalhado.txt"
EPHEMERAL_OUTPUT="output_ephemeral.csv"

# Função para coletar os IPs do GCP e salvar em CSV
function collect_gcp_ips {
    echo "🔍 Coletando IPs do GCP para a organização $ORG_ID..."
    gcloud asset search-all-resources \
      --scope=organizations/$ORG_ID \
      --asset-types='compute.googleapis.com/Address' \
      --read-mask='*' \
      --format=json | jq -r '.[] | select(.versionedResources) | .project as $p | .versionedResources[] | "\(.resource.address)"' > "$OUTPUT_FILE"

    if [[ -s $OUTPUT_FILE ]]; then
        echo "✅ IPs do GCP coletados com sucesso! Salvo em $OUTPUT_FILE"
    else
        echo "⚠️ Nenhum IP foi encontrado ou erro na coleta!"
    fi
}

# Função para comparar os IPs do GCP com um arquivo CSV fornecido pelo usuário
function compare_ips {
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        echo "⚠️ O arquivo $OUTPUT_FILE não foi encontrado! Execute a opção 1 primeiro."
        return
    fi

    read -p "📄 Digite o caminho do arquivo CSV com a lista de IPs para comparar: " CUSTOM_IP_FILE

    if [[ ! -f "$CUSTOM_IP_FILE" ]]; then
        echo "❌ O arquivo fornecido não existe! Tente novamente."
        return
    fi

    echo "🔍 Comparando IPs..."
    echo "IP_GCP,IP_FORNECIDO" > "$COMPARE_OUTPUT"

    while IFS=, read -r USER_IP; do
        MATCH=$(grep -Fx "$USER_IP" "$OUTPUT_FILE")

        if [[ -n "$MATCH" ]]; then
            echo "$MATCH,$USER_IP" >> "$COMPARE_OUTPUT"
        else
            echo "NÃO ENCONTRADO,$USER_IP" >> "$COMPARE_OUTPUT"
        fi
    done < "$CUSTOM_IP_FILE"

    echo "✅ Comparação concluída! Resultado salvo em $COMPARE_OUTPUT"
}

# Função para coletar informações detalhadas do GCP e salvar em CSV
function collect_gcp_detailed {
    echo "🔍 Coletando informações detalhadas dos IPs do GCP para a organização $ORG_ID..."
    gcloud asset search-all-resources \
      --scope=organizations/$ORG_ID \
      --asset-types='compute.googleapis.com/Address' \
      --read-mask='*' \
      --format=json | jq -r '.[] | select(.versionedResources) | .project as $p | .versionedResources[] | "\($p),\(.resource.name),\(.resource.id),\(.resource.address),\(.resource.addressType)"' > "$DETAILED_OUTPUT_CSV"

    if [[ -s $DETAILED_OUTPUT_CSV ]]; then
        echo "✅ Informações detalhadas coletadas com sucesso! Salvo em $DETAILED_OUTPUT_CSV"
    else
        echo "⚠️ Nenhuma informação detalhada foi encontrada ou erro na coleta!"
    fi
}

# Função para coletar informações detalhadas e formatar com awk para TXT
function collect_gcp_detailed_txt {
    echo "🔍 Coletando e formatando informações detalhadas dos IPs do GCP para a organização $ORG_ID..."
    
    collect_gcp_detailed
    
    awk -F ',' '{print "Project: "$1"\nName: "$2"\nID: "$3"\nAddress: "$4"\nAddressType: "$5"\n---"}' "$DETAILED_OUTPUT_CSV" > "$DETAILED_OUTPUT_TXT"

    if [[ -s $DETAILED_OUTPUT_TXT ]]; then
        echo "✅ Informações detalhadas salvas e formatadas com awk em $DETAILED_OUTPUT_TXT"
    else
        echo "⚠️ Ocorreu um erro ao gerar o arquivo TXT!"
    fi
}

# Função para coletar apenas os IPs com a flag ephemeral (true ou false)
function collect_ephemeral_ips {
    echo "🔍 Coletando informações sobre IPs ephemeral do GCP para a organização $ORG_ID..."
    gcloud asset search-all-resources \
      --scope=organizations/$ORG_ID \
      --asset-types='compute.googleapis.com/Address' \
      --read-mask='*' \
      --format=json | jq -r '.[] | select(.versionedResources) | .project as $p | .versionedResources[] | "\($p),\(.resource.name),\(.resource.id),\(.resource.address),\(.resource.addressType),\(.resource.labels.ephemeral // "N/A")"' > "$EPHEMERAL_OUTPUT"

    if [[ -s $EPHEMERAL_OUTPUT ]]; then
        echo "✅ Informações sobre IPs ephemeral coletadas com sucesso! Salvo em $EPHEMERAL_OUTPUT"
    else
        echo "⚠️ Nenhum IP ephemeral encontrado ou erro na coleta!"
    fi
}

# Menu interativo
while true; do
    echo "==============================="
    echo "📌 GCP IP Checker - Menu (Org: $ORG_ID)"
    echo "==============================="
    echo "1️⃣ - Coletar IPs do GCP (simples) e salvar em output.csv"
    echo "2️⃣ - Comparar IPs do GCP com um CSV fornecido"
    echo "3️⃣ - Coletar informações detalhadas do GCP e salvar em output_detalhado.csv"
    echo "4️⃣ - Coletar e formatar informações detalhadas em output_detalhado.txt"
    echo "5️⃣ - Coletar IPs marcados como ephemeral e salvar em output_ephemeral.csv"
    echo "6️⃣ - Sair"
    echo "==============================="
    read -p "👉 Escolha uma opção: " OPTION

    case $OPTION in
        1) collect_gcp_ips ;;
        2) compare_ips ;;
        3) collect_gcp_detailed ;;
        4) collect_gcp_detailed_txt ;;
        5) collect_ephemeral_ips ;;
        6) echo "🚀 Saindo..."; exit ;;
        *) echo "❌ Opção inválida! Escolha entre 1 e 6." ;;
    esac
done


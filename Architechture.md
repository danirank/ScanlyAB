# Teknisk reflektion – Scanly AB

## 1. Container Apps

Vi deployar Scanly API till Azure Container Apps eftersom lösningen består av en fristående containeriserad API-tjänst och vi vill slippa drifta Kubernetes-klustret själva. Container Apps ger oss extern ingress, revisioner och skalning, medan Azure sköter kontrollplanet och underliggande noder. I vår Bicep-konfiguration kör stage med 0,25 vCPU/0,5 GiB och en replik, medan prod får 0,5 vCPU/1 GiB och kan skala från en till fem repliker. Begränsningen är mindre kontroll över Kubernetes-resurser, nätverk, specialiserad schemaläggning och avancerade deploymentmönster än i AKS. Vi skulle välja AKS om Scanly växte till många mikrotjänster som behöver Kubernetes-specifika funktioner, exempelvis egna operators, särskilda node pools, DaemonSets eller mycket detaljerad nätverkspolicy.

## 2. CI/CD

När kod pushas till `main` startar Azure DevOps-pipelinen `ci_cd.yaml`: den checkar ut repot, installerar .NET 10, kör `dotnet restore` och bygger API-projektet i Release-läge. Om restore eller build misslyckas avslutas pipelinen där, så ingen image pushas och den redan fungerande versionen i Container App fortsätter att köras. Vid ett lyckat bygge loggar pipelinen in i Azure Container Registry via service connection, bygger Docker-imagen och taggar den med Azure DevOps Build ID. Imagen pushas till `scanlystageacr.azurecr.io`, och sedan uppdateras `scanly-stage-api` med just den taggen vilket skapar en ny Container Apps-revision. Det finns även en GitHub Actions-workflow som kör vid ändringar i `ScanlyApi/**`, men den gör för närvarande bara restore och build; den deployar inte.

## 3. IaC

Vi beskriver ACR, Container Apps Environment, Container App, Storage Account och behörigheter i Bicep så att samma miljö kan skapas om utan manuella portalsteg. `main.bicep` är gemensam, medan `stage.bicepparam` och `prod.bicepparam` anger olika SKU:er, resurser och skalningsgränser. Idempotens betyder att vi kan köra samma Bicep-deployment flera gånger och få resurserna i det deklarerade önskade läget, i stället för dubbletter eller oförutsägbara ändringar. Det gör drift mer repeterbar, möjliggör kodgranskning av infrastruktur och minskar risken att stage och prod skiljer sig av misstag. Scriptet `deploy.sh` använder dessutom Bicep-outputen för appens URL och kör sedan ett `/health`-test, så en deployment kan verifieras direkt.

## 4. Säkerhet

Vi lägger inga nycklar i Bicep, källkod eller pipelinefilen: Azure DevOps använder en service connection för inloggning och Container App har systemtilldelad managed identity. Identiteten får minsta nödvändiga behörigheter genom rollerna `AcrPull` på ACR och `Storage Blob Data Contributor` på Storage Account; ACR:s admin-användare är dessutom avstängd. API:t kan använda `AZURE_DI_KEY` som miljövariabel för Document Intelligence, men vår föredragna lösning i Azure är `DefaultAzureCredential` med managed identity och rollen `Cognitive Services User`, så att någon nyckel inte behöver hanteras av appen. Om en nyckel ändå hamnar i git-historiken betraktar vi den som läckt: vi återkallar eller roterar den omedelbart, ersätter den där den används och kontrollerar åtkomstloggar. Att bara ta bort raden i en ny commit räcker inte, utan historiken ska saneras och vi ska skanna repot efter fler hemligheter.

# 5. Ekonomi

Kostnadsberäkningen utgår från att varje faktura i genomsnitt består av **en sida** och att både stage- och produktionsmiljön kör sina minsta antal repliker dygnet runt, motsvarande **730 timmar per månad**.

Samtliga USD-belopp baseras på publicerade listpriser och har räknats om till svenska kronor med en antagen växelkurs på **1 USD = 10,50 SEK**.

## 5.1 Fasta månadskostnader

| Resurs | Kostnad (USD/mån) | Motivering |
|---|---:|---|
| Container Apps – Stage | 14,31 | 0,25 vCPU / 0,5 GiB, en replik |
| Container Apps – Prod | 28,62 | 0,5 vCPU / 1 GiB, en replik |
| Azure Container Registry | 25,81 | Ett Basic-register för stage och ett Standard-register för prod |
| Azure Blob Storage | 0,23 | 10 GB Hot ZRS. Endast resultat i JSON-format lagras. |
| **Totalt** | **68,97** | **Cirka 724 kr/månad** |

## 5.2 Kostnad vid olika kundvolymer

Vi har beräknat två scenarier: ett vid lansering och ett efter ett års tillväxt.

| | Lansering | År 1 |
|---|---:|---:|
| Antal kunder | 30 | 200 |
| Antal fakturor/månad | 15 000 | 100 000 |
| Document Intelligence | 140,00 USD | 990,00 USD |
| Fast infrastruktur | 68,97 USD | 68,97 USD |
| **Total månadskostnad** | **208,97 USD** | **1 058,97 USD** |
| **Total i SEK** | **2 194 kr** | **11 119 kr** |
| Kostnad per faktura | 14,6 öre | 11,1 öre |
| **Beräknad månadsintäkt** | **8 970 kr** | **59 800 kr** |

## 5.3 Beräkning av Document Intelligence

Kostnaden för Azure Document Intelligence baseras på antalet analyserade sidor. De första **1 000 sidorna per månad** ingår utan extra kostnad. Därefter tillämpas ett pris på **10 USD per 1 000 sidor**.

Med antagandet att varje faktura består av en sida blir beräkningen följande:

- **Lansering:** 15 000 fakturor − 1 000 inkluderade sidor = 14 000 debiterbara sidor. Kostnad: 140 USD/månad.
- **År 1:** 100 000 fakturor − 1 000 inkluderade sidor = 99 000 debiterbara sidor. Kostnad: 990 USD/månad.

Kostnaden per faktura minskar när antalet behandlade fakturor ökar, eftersom den fasta infrastrukturkostnaden fördelas över en större volym.

## 5.4 Källor och prisantaganden

Kostnadsberäkningarna baseras på Microsoft Azures publicerade listpriser för följande tjänster:

- [Azure Container Apps](https://azure.microsoft.com/en-us/pricing/details/container-apps/)
- [Azure Container Registry](https://azure.microsoft.com/en-us/pricing/details/container-registry/)
- [Azure Blob Storage](https://azure.microsoft.com/en-us/pricing/details/storage/blobs/)
- [Azure Document Intelligence](https://azure.microsoft.com/en-us/pricing/details/ai-document-intelligence/)

**Datum för priskontroll:** 2026-09-25.

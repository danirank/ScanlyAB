# Individuell reflektion — Teamlabb

## 1. Min roll i teamet

Mitt huvudsakliga bidrag var arbetet med Azure-infrastrukturen och driftsättningen. Jag arbetade med att strukturera Bicep-filerna kring en `main.bicep` och separata parameterfiler för stage och prod, så att samma infrastrukturkod kunde återanvändas med olika resursinställningar. Jag arbetade även med ett Bash-skript för driftsättning som kör `az deployment group create`, hämtar Container App-adressen från deploymentens outputs och anropar ett separat skript för registrering av appen.

En stor del av arbetet handlade om att felsöka kopplingen mellan Azure Container Apps och Azure Container Registry (ACR). Jag undersökte bland annat hur Managed Identity och rollen `AcrPull` ska användas för att Container Apps ska kunna hämta en image. 

## 2. Det svåraste momentet

Det svåraste var att få hela driftsättningskedjan att fungera, särskilt när Container Apps inte kunde hämta imagen från ACR. Ett konkret fel var `UNAUTHORIZED` vid hämtning av en image från stage-registret. Det räckte alltså inte att imagen hade byggts och laddats upp: den körande applikationen behövde också rätt behörighet för att kunna hämta den.

Jag undersökte hur registret, appens identitet och rolltilldelningen hängde ihop. Lösningen jag arbetade mot var att låta Container App använda Managed Identity och tilldela den `AcrPull` på rätt register. Ett närliggande problem var att skilja mellan fel i själva infrastrukturdriftsättningen och fel som uppstår när en ny apprevision ska starta. Jag började därför se separat på resursdeployment, imageåtkomst, revisionsstatus och hälsokontroll i stället för att behandla allt som ett enda deployfel.

## 3. Vad förstår jag nu som jag inte förstod innan?

Jag förstår tydligare varför infrastrukturdriftsättning och applikationsdriftsättning bör hanteras separat. Bicep beskriver vilka Azure-resurser som ska finnas och hur de ska vara konfigurerade. Applikationspipelinen hanterar i stället den kod som ska köras i resurserna. Genom att separera dem behöver inte varje kodändring innebära att infrastrukturen driftsätts på nytt.

Jag förstår också varför Managed Identity kombineras med rollbaserad åtkomstkontroll. Att en Container App känner till adressen till ett register betyder inte att den har rätt att läsa därifrån. Identiteten anger *vem* appen är, medan `AcrPull` anger *vad* den får göra. Den uppdelningen gör att man slipper lägga in registerlösenord i applikationens konfiguration.

## 4. Vad skulle jag göra annorlunda?

Jag skulle ha bestämt gränsen mellan infrastruktur och applikationspipeline redan första dagen. Jag skulle börja med att skapa stage-miljön manuellt via Bicep, kontrollera att Managed Identity har rätt åtkomst till ACR och först därefter koppla på pipelinen som bygger och driftsätter applikationen. Jag skulle också lägga till ett automatiskt hälsotest direkt. Då hade det varit enklare att identifiera om ett fel låg i behörigheterna, imagen eller själva applikationen, utan att felsöka hela kedjan samtidigt.

## 5. Arkitektur och ekonomi

Den beräknade fasta kostnaden är cirka **724 kr per månad** med våra antaganden om en ständigt körande replik i stage och en i prod. I den summan ingår Container Apps, ACR och Blob Storage. Därutöver tillkommer en rörlig kostnad för Azure Document Intelligence, som beror på hur många fakturasidor som behandlas. Kalkylen förutsätter att en faktura i genomsnitt motsvarar en sida och använder omräkningen 1 USD = 10,50 kr. Det är en uppskattning, inte en garanterad faktura; loggning, ökad skalning och andra tillkommande tjänster kan påverka utfallet.

Jag ser två särskilt viktiga sårbarheter. Den tekniska är beroendet av att produktionsappen kan hämta rätt image och starta en fungerande revision. Jag skulle därför prioritera verifierad registeråtkomst, hälsokontroller och möjlighet att gå tillbaka till en tidigare fungerande revision. Den ekonomiska är den rörliga kostnaden för dokumentanalysen: om fakturavolymerna eller antalet sidor per faktura ökar kan den delen växa betydligt snabbare än den fasta infrastrukturen. Jag skulle följa upp både misslyckade analyser och kostnaden per behandlad faktura.

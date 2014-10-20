Mastedatabasen
==============

Denne animation viser udrulningen af mobilmaster i Danmark i perioden 1991-2014. Klik på animationen for at se den originale video på Flickr.

[![Mastedatabasen](https://raw.githubusercontent.com/wulff/perl-mastedatabasen/master/img/master.gif)](https://www.flickr.com/photos/nidhug/15472267396/)

Få fat i data
-------------

Data om danske antennemaster finder man i [Erhvervsstyrelsens Mastedatabase](http://mastedatabasen.dk/). Databasen indeholder data om flere forskellige [tjenestearter](http://mastedatabasen.dk/Master/antenner/tjenester.xml), men jeg er kun interesserede i mobiltelefoni, så jeg kører følgende kommando for at hente informationer om alle mobilmaster:

    curl "http://mastedatabasen.dk/Master/antenner.json?tjeneste=2&maxantal=50000" > master.json

Rens data
---------

Før jeg kan begynde at lege med de downloadede data skal jeg have ryddet lidt op i dem. Jeg har kun brug for nogle få af de felter, som databasen stiller til rådighed, så jeg bruger et Perl-script til at filtrere data.

Databasen indholder en del misvisende poster – der er f.eks. en del registreringer af master med LTE-teknologi som er dateret lang tid før teknologien blev opfundet. Jeg bruger følgende idriftsættelsesdatoer til at få sat skik på tingene:

* **GSM:** Idriftsættelse november 1991 ([kilde](http://www.telenor.dk/om_telenor/organisation/historie/))
* **UMTS:** Idriftsættelse oktober 2003 ([kilde](http://en.wikipedia.org/wiki/List_of_UMTS_networks#Europe))
* **LTE:** Idriftsættelse december 2010 ([kilde](http://www.computerworld.dk/art/112758/nu-er-det-her-telia-lancerer-4g-i-danmark))

(Databasen indeholder information om [flere teknologier](http://mastedatabasen.dk/Master/antenner/teknologier.json), men jeg holder mig til de mobil-relaterede i denne omgang.)

Scriptet `master.pl` læser de downloadede data fra Mastedatabasen og laver fire sepearate GeoJSON-filer: Én for hver af de tre teknologier og én med alle teknologierne samlet.

Rendér data i QGIS
------------------

Næste skridt er at tilføje de generede GeoJSON-filer til et nyt QGIS-projekt.

Jeg opretter et nyt projekt og tilføjer Europas kystlinje som baggrundslag, derefter bliver den stylet så den ikke er alt for anmassende. Kystlinjen kan downloades som shape-fil fra [Det Europæiske Miljøagentur](http://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis/gis-data/europe-coastline-shapefile).

![QGIS screenshot](https://raw.githubusercontent.com/wulff/perl-mastedatabasen/master/img/qgis.png)

Derefter importeres hver GeoJSON-filerne til projektet, og hvert nyt lag duplikeres. Det er nødvendigt for at kunne lave en tydelig markering af de positioner, som tilføjes i et givet tidsrum. Jeg vælger at nye positioner skal vises med en stor, klar rød prik, mens eksisterende positioner vises med en mindre, mere dæmpet rød prik.

Derefter bruger jeg Anita Grasers [TimeManager plugin](https://plugins.qgis.org/plugins/timemanager/) til at lave en animation på basis af de timestamps som findes i Mastedatabasen. Det nemmeste er at følge Anitas glimrende [vejledning](http://anitagraser.com/2011/11/20/nice-animations-with-time-managers-offset-feature/).

![QGIS Time Manager screenshot](https://raw.githubusercontent.com/wulff/perl-mastedatabasen/master/img/qgis-tm.png)

Når start- og sluttidspunkt samt animationsintervallet (1 måned pr. frame i dette tilfælde) ser fornuftigt ud trykker jeg på *Export Video* for at eksportere alle animationens frames som PNG-filer. Det er ikke helt oplagt hvordan man kan styre opløsningen på de eksporterede filer, så i første omgang justerede jeg QGIS' viewport manuelt til 1280×720 pixels.

Jeg eksporterer fire samlinger af frames: Én for hver af de tre teknologier og én med alle teknologierne samlet.

Saml stumperne
--------------

Til sidst bruger jeg Motion til at samle de fire sekvenser af PNG-filer til én 720p video. Det er også her jeg tilføjer de fire labels og timeren (én af Motions tekstgeneratorer).

![QGIS Time Manager screenshot](https://raw.githubusercontent.com/wulff/perl-mastedatabasen/master/img/motion.png)

GIF-animationen i toppen af denne README er genereret fra den færdige video, som jeg eksporterede fra Motion. Følgende kommandoer (baseret på svarene til [dette spørgsmål på SuperUser](http://superuser.com/questions/436056/how-can-i-get-ffmpeg-to-convert-a-mov-to-a-gif)) resulterer i en GIF som ikke er ulideligt stor:

    ffmpeg -ss 00:00:00.000 -i master-filtered.mov -pix_fmt rgb24 -r 10 -s 728x410 -t 00:00:11.400 master.gif
    convert -layers Optimize master.gif master-optimized.gif

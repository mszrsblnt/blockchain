## Blockchain - HF2 L(a)unch Codes

### Feladatleírás
Egy magas biztonsági létesítmény mindig két katonát igényel egy műszakban. Emellett rendszeres hozzáférést kell biztosítania alacsony biztonsági szintű engedélyekkel rendelkező személyeknek (ételkiszállítás, takarítás stb.). Az összes belépést és kilépést nyomon kell követni és engedélyezni egy elosztott könyvelési rendszer által (a főbejáraton egy elektronikus zár folyamatosan figyeli a könyvet és eldönti, hogy nyitva vagy zárva kell-e lennie; kérések és engedélyezések okos kártyákkal és elektronikus terminálokkal támogatottak).

1. A belépést kívülről kérni kell, és mindkét ügyeletes katonának jóvá kell hagyja.
2. A sikeres belépést belsőleg naplózni kell a belépő fél által (miután az ajtót bezárták).
3. A kilépés protokollja ugyanez visszafelé.
4. A váltások két fázisban történnek (először, katona1 kiváltja katona1-et egy teljes belépés-kilépési ciklusban, majd katona2 követi ugyanezt).
5. Az őrszolgálatot kölcsönös "elismerés" által adhatja át a két érintett katona.
6. Ne legyen több, mint három személy a létesítményben egyszerre.
7. A váltás akkor következik be, amikor a létesítmény üres, és nem engedélyezett a belépés, amíg ez be nem fejeződik.
8. Az őrök nem léphetnek be vagy léphetnek ki a létesítményből őrszolgálatban.


### Készítők
- Ágota Benedek [WFXBHI]
- Mészáros Bálint [B3SWVC]


<<<<<<< HEAD
### Tervezési döntések
A tervezés során az alábbi döntéseket hoztuk meg:

- max létszám őrőkkel egyutt 3
- ajtonyitas es zaras egy fuggvenyen belul, eventet kuld
- 

1.  **Mindig két őr szükséges:** A létesítmény létrehozásához alapból két őr szükséges.
    
2.  **Belépési/kilépési kérelmek és jóváhagyások:** A belépési és kilépési folyamatok szabályozásához kérelmeket használunk, amelyeket mindkét őrnek jóvá kell hagynia a művelet végrehajtásához.
    
3.  **Őrváltás két fázisban:** Az őrváltás két lépésben történik, hogy biztosítsuk, hogy mindig legalább egy őr a létesítményben maradjon.
    
4.  **Naplózás:** Minden belépési és kilépési eseményt naplózunk, hogy vissza lehessen követni a történéseket és biztosítsuk a felelősségvállalást. 

### Adatmodel
A smart contract az alábbi adatmodellt használja:
1.  `uint public constant MAX_INSIDE = 3;`: Nyilvános, konstans egész típusú változó, amely a maximális létesítményben tartózkodó személyek számát tárolja. A könnyű módosíthatóság és átláthatóság miatt lett kiszervezve.
    
2.  `string[] private logs;`: Privát string tömb, amelyben tároljuk a belépési és kilépési eseményeket.
    
3.  `bool public isDoorOpen;`: Publikus logikai változó, amely jelzi, hogy az ajtó nyitva vagy zárva van-e.
    
4.  `address public firstGuard;`: Publikus address típusú változó, amely tárolja az első őr címét.
    
5.  `address public secondGuard;`: Publikus address típusú változó, amely tárolja a második őr címét.
    
6.  `address[] public membersInside;`: Publikus address tömb, amelyben tároljuk a létesítményben tartózkodó tagok címeit. (Beleértve a két őr címét is.)
    
7.  `bool public isChangingGuard;`: Publikus logikai változó, amely jelzi, hogy az őrváltás folyamatban van-e.
    
8.  `bool public isFirstGuardChanged;`: Publikus logikai változó, amely jelzi, hogy az első őr már le lett-e cserélve.
    
9.  `struct GuardChange { ... }`: Ez egy struktúra, amely az őrváltásokat tárolja.
      - `address newGuard`: Az új őr címe.
      - `bool newGuardAcknowledged`: Jelenlegi őr elismerte-e az őrváltást.
      - `bool currentGuardAcknowledged`: Új őr elismerte-e az őrváltást.
    
10.  `mapping(address => uint) private guardChangesMapping;`: Ez egy privát mapping, amely az őrváltások indexeit tárolja az adott címhez rendelve.
    
11.  `GuardChange[2] private guardChanges;`: Ez egy privát GuardChange típusú tömb, amelyben tároljuk az őrváltásokat.
    
12.  `struct Request { ... }`: Ez egy struktúra, amely a belépési és kilépési kérelmeket tárolja.
      - `bool isEnter`: Belépésre vonatkozik-e.
      - `bool firstGuardApproved`: Első őr jóváhagyta-e már a kérelmet.
      - `bool secondGuardApproved`: Második őr jóváhagyta-e már a kérelmet.
    
13.  `mapping(address => Request) public requests;`: Ez egy nyilvános mapping, amely a kérelmeket tárolja az adott címhez rendelve.

### Függvények - API
=======
### Függvények
>>>>>>> bb73c7210d74a9fc35171f5a3b60431b20b85c75

#### Konstruktor (`constructor`)

```solidity
constructor(address _firstGuard, address _secondGuard)
```

- Paraméterek:
  - `_firstGuard`: Az első őr címe.
  - `_secondGuard`: A második őr címe.
- Feladat:
  - Beállítja az első és második őr címét, és hozzáadja őket az `membersInside` tömbhöz.
  - Beállítja az `isDoorOpen` értékét hamisra és az `isChangingGuard` értékét hamisra.

#### Belépési kérelem (`requestEnter`)

```solidity
function requestEnter() external onlyMembersOutside
```

- Feladat:
  - Hozzáadja a küldőt a belépésikéréslistához.

#### Belépés jóváhagyása (`approveEnter`)

```solidity
function approveEnter(address member) external onlyGuard
```

- Paraméter:
  - `member`: Az a cím, akinek jóvá akarjuk hagyni a belépését.
- Feladat:
  - Jóváhagyja a belépést az adott tag számára.

#### Belépés végrehajtása (`doEnter`)

```solidity
function doEnter() external approved onlyMembersOutside
```

- Feladat:
  - Végrahajtja a belépést, ha a kérelmet beküldő tag bent van, és mindkét őr jóváhagyta.
  - Naplózza a belépést.
  - DoorOpen eventet küld.

#### Kilépési kérelem (`requestExit`)

```solidity
function requestExit() external onlyMembersInside
```

- Feladat:
  - Hozzáadja a küldőt a kilépésikéréslistához.

#### Kilépés jóváhagyása (`approveExit`)

```solidity
function approveExit(address member) external onlyGuard
```

- Paraméter:
  - `member`: A kilépési kérelmet beküldő cím.
- Feladat:
  - Jóváhagyja a kilépést az adott tag számára.

#### Kilépés végrehajtása (`doExit`)

```solidity
function doExit() external approved onlyMembersInside
```

- Feladat:
  - Végrehajtja a kilépést, ha a tag bent van, és mindkét őr jóváhagyta.
  - Naplózza a kilépést.
  - DoorOpen eventet küld.

#### Őrváltás kezdeményezése (`beginChangingGuard`)

```solidity
function beginChangingGuard(address _newGuard1, address _newGuard2) external onlyGuard
```

- Paraméterek:
  - `_newGuard1`: Az első új őr címe.
  - `_newGuard2`: A második új őr címe.
- Feladat:
  - Kezdeményezi az őrváltást.

#### Őrváltás elismerése (`acknowleChangeGuard`)

```solidity
function acknowleChangeGuard() external
```

- Feladat:
  - Az őrség átadása azzal, hogy a két őr kölcsönösen elismeri a váltást.

#### Elismerések ellenőrzése(`checkAcnknowledges`)

```solidity
checkAcnknowledges(address _sender, address currentGuard) internal returns (bool)
```

- Paraméterek:
  - `_sender`: Az elismerés hívója.
  - `_currentGuard`: Az őr, akit éppen lecserélnek.
- Feladat:
  - Ellenőrzi, hogy elismerték-e az átadást az őrök.
- Visszatétési érték:
  - Elfogadta-e mindtkét őr az átadást

#### Logok lekérdezése (`getLogs`)

```solidity
function getLogs() external view returns (string[] memory)
```

- Feladat:
  - Visszaadja az összes naplóbejegyzést.
- Visszatérési érték:
  - Logok string tömbként

#### Tele van-e a létesítmény? (`isFacilityFull`)

```solidity
function isFacilityFull() external view returns (bool)
```

- Feladat:
  - Ellenőrzi, hogy a létesítmény tele van-e.
- Visszatérési érték:
  - Tele van-e a létesítmény

#### Őrváltás lekérdezése (`getGuardChange`)

```solidity
function getGuardChange(address _sender) private view returns (GuardChange storage) 
```

- Paraméterek:
  - `_sender`: Azonosító, amihez a tartozó örváltási adataokat lekérjük.
- Feladat:
  - Az őrváltás adatainak lekérdezése.
- Visszatérési érték
  - Az őrváltás adatai

#### Tag bentlétének ellenőrzése (`checkIfMemberIsInside`) 

```solidity
function checkIfMemberIsInside(address member) public view returns (bool)
```

- Paraméterek:
  - `member`: Tag, akit ellenőrzünk.
- Feladat:
  - Visszaadja, hogy a tag bent van-e a létsítményben.
- Visszatérési érték:
  - A tag bent van-e

#### Cím ASCII sztringé alakítása (`toAsciiString`) 

```solidity
function toAsciiString(address x) internal pure returns (string memory)
```

A függvény forrása: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string

- Paraméterek:
  - `x`: Cím, amit átalkít a függvény
- Feladat:
  - Átalakítja a címet.
- Visszatérési érték:
  - Az átkonvertált cím


#### Karakter konverzió (`char`)

```solidity
function char(bytes1 b) internal pure returns (bytes1 c)
```

 függvény forrása: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string

- Paraméterek:
  - `b`: Az átalakítandó `bytes1` típusú bájt
- Feladat:
  - Az `b` bájt átalakítása megfelelő ASCII karakterré.
- Visszatérési érték:
  - Az átalakított ASCII karakter `bytes1` típusban.

### Modifierek

#### Engedélyezve (`approved`)

```solidity
modifier approved()
```

- Feladat:
  - Ellenőrzi, hogy az adott műveletet kezdeményező tagnak mindkét őr jóváhagyta-e a műveletet.

#### Csak őrők (`onlyGuard`)

```solidity
modifier onlyGuard()
```

- Feladat:
  - Ellenőrzi, hogy csak az őrök hívhatják-e meg a modifikált függvényt.

#### Csak bent lévők (`onlyMembersInside`)

```solidity
modifier onlyMembersInside()
```

- Feladat:
  - Ellenőrzi, hogy csak azok a tagok hívhatják-e meg a modifikált függvényt, akik a létesítményben vannak.

#### Csak kint lévők (`onlyMembersOutside`)

```solidity
modifier onlyMembersOutside()
```

- Feladat:
  - Ellenőrzi, hogy csak azok a tagok hívhatják-e meg a modifikált függvényt, akik nincsenek a létesítményben.

### Tesztek

<<<<<<< HEAD
A smart contract-hez számos tesztet írtak, amelyek lefedik a különböző működési lehetőségeket és körülményeket. Ezeket a teszteket TypeScipt nyelven írtuk meg.

=======
>>>>>>> bb73c7210d74a9fc35171f5a3b60431b20b85c75
#### Deployment

1. **Helyes kezdőértékek beállítása**
   - Leírás: Ellenőrzi, hogy a telepítés során a megfelelő kezdőértékek kerültek-e beállításra.
   - Elvárt viselkedés:
     - Az ajtó kezdetben zárva van.
     - Az első és második őr címei megfelelően vannak beállítva.
     - Az őrváltás nincs folyamatban.

#### Belépés

1. **Belépés engedélyezése kérésre és mindkét őr jóváhagyása esetén**
   - Leírás: Ellenőrzi, hogy a belépés megengedett-e, amikor azt az összes őr jóváhagyta.
   - Elvárt viselkedés:
     - Az összes őr jóváhagyása után a tag sikeresen beléphet.
     - Az adott tag belépése sikeres volt, és az őrzők jóváhagyása után a belépési kérelmek törlődnek.
     - A belépési esemény rögzítésre kerül a naplóban.

2. **Belépés megtagadása mindkét őr jóváhagyása nélkül**
   - Leírás: Ellenőrzi, hogy a belépés megtagadódik-e, ha legalább az egyik őr nem jóváhagyta.
   - Elvárt viselkedés:
     - Ha legalább az egyik őr nem hagyta jóvá a belépést, a belépési kísérlet visszautasításra kerül.

3. **Belépés megtagadása, ha a létesítmény tele van**
   - Leírás: Ellenőrzi, hogy a belépés megtagadódik-e, ha a létesítmény tele van.
   - Elvárt viselkedés:
     - Ha a létesítmény megtelt, a belépési kísérlet visszautasításra kerül.

#### Kilépés

1. **Szolgálatban lévő őr kilépésének megtagadása**
   - Leírás: Ellenőrzi, hogy az őrök a szolgálatban tartózkodásuk során történő kilépése megtagadódik-e.
   - Elvárt viselkedés:
     - Az őröknek nem szabad kilépniük, amikor őrszolgálatban vannak.

2. **Kilépés engedélyezése kérésre és mindkét őr jóváhagyása esetén**
   - Leírás: Ellenőrzi, hogy a kilépés megengedett-e, amikor azt az összes őr jóváhagyta.
   - Elvárt viselkedés:
     - Az összes őr jóváhagyása után a tag sikeresen kiléphet.
     - Az adott tag kilépése sikeres volt, és az őrzők jóváhagyása után a kilépési kérelmek törlődnek.
     - A kilépési esemény rögzítésre kerül a naplóban.

3. **Kilépés megtagadása, ha nem nem lett jóváhagyva mindkét őr által**
   - Leírás: Ellenőrzi, hogy a kilépés megtagadódik-e, ha legalább az egyik őr nem hagyta jóvá.
   - Elvárt viselkedés:
     - Ha legalább az egyik őr nem hagyta jóvá a kilépést, a kilépési kísérlet visszautasításra kerül.

#### Őrváltás

1. **Mindkét őr cseréje**
   - Leírás: Ellenőrzi, hogy az őrváltás sikeresen megtörténik-e.
   - Elvárt viselkedés:
     - Az új őrök belépnek és átveszik az őrszolgálatot, miközben az előző őrök kilépnek.
     - Őrváltás alatt a megfelelő naplóbejegyzések történnek.

2. **Az őrváltás megtagadása, ha a létesítmény tele van**
   - Leírás: Ellenőrzi, hogy az őrváltás megtagadódik-e, ha a létesítmény tele van.
   - Elvárt viselkedés:
     - Ha a létesítmény megtelt, az őrváltás megtagadódik.

3. **Belépés megtagadása az őrváltás idején**
   - Leírás: Ellenőrzi, hogy az őrváltás alatt a belépés megtagadódik-e.
   - Elvárt viselkedés:
     - Őrváltás alatt a belépési kísérlet visszautasításra kerül.

4. **Csak szolgálatban levő őr kezdeményezhet őrváltást**
   - Leírás: Ellenőrzi, hogy csak az őrök kezdeményezhetik-e az őrváltást.
   - Elvárt viselkedés:
<<<<<<< HEAD
     - Az őrváltás csak az őrszolgálatban levő őrök által kezdeményezhető.

### Útmutató a tesztek futtatásához

1. **Függőségek telepítése**
    - Klónozza le a projektet a GitHub tárolóból.
    - Telepítse a szükséges függőségeket a **'npm install'** paranccsal.

2. **Tesztek futtatása**
    - Az **'npx hardhat compile'** parancs segítségével építse fel a szerződést. 
    - Futtassa a teszteket a **'npx hardhat test'** paranccsal.
    - Ellenőrizze a tesztek kimenetét és bizonyosodjon meg róla, hogy minden teszteset sikeresen lefutott.
=======
     - Őrváltás csak az őrszolgálatban levő őrök által kezdeményezhető.
>>>>>>> bb73c7210d74a9fc35171f5a3b60431b20b85c75

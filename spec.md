# Spécifications Techniques : Brainrot Defense (Adaptation Risk PvZ)

## 1. Concept Global
Un jeu de stratégie au tour par tour sur une grille (Tile-based), mélangeant les mécaniques de "Tower Defense" et de jeu de plateau "Risk".
- **Style Visuel :** "Toy/Board Game" (Plastique lisse, figurines rigides) mélangé à une esthétique "Brainrot" (Mèmes internet, couleurs saturées).
- **Core Loop :** Lancer de dés -> Allocation (Spawn vs Action) -> Déplacement auto -> Combat.

## 2. Mécaniques de Jeu (Game Rules)
### 2.1 La Grille (The Board)
- Dimensions : 5 Lignes x 9 Colonnes.
- Zone Gauche (Col 1-8) : "The Ohio Lawn" (Placement des unités Brainrot).
- Zone Droite (Col 9) : "The Skibidi Street" (Spawn des Zombies).
- Interaction : Raycasting depuis la caméra pour sélectionner les cases.

### 2.2 Système de Tour (Turn-Based System)
Une machine à états (FSM) stricte gère le flux :
1. **Dice Phase :** Le joueur lance 2 dés (1-6). Il doit allouer un dé aux "Renforts" (Spawn) et un aux "Actions".
2. **Spawn Phase :** Placement des unités selon le budget "Renforts".
3. **Auto-March :** Tous les Zombies avancent d'une case vers la gauche.
   - *Collision :* Si contact avec une unité Brainrot -> Combat "Manger" (50% chance kill).
4. **Action Phase :** Le joueur dépense ses points d'action pour activer des capacités spéciales ou attaquer.

### 2.3 Unités et Rareté (Gacha System)
Les unités ont des stats basées sur leur rareté (Common, Rare, Legendary) :
- **Brainrot (Défenseurs) :**
  - *Skibidi Toilet (Common) :* Tireur de base (1 dé de défense).
  - *Gigachad (Legendary) :* Tank + Dégâts de zone (3 dés de défense).
- **Zombies (Attaquants) :**
  - *Basic Zombie :* Avance tout droit.
  - *Nike Shark :* Vitesse double (saute une case).

## 3. Architecture Technique (Roblox/Luau)
- **Outils :** Rojo pour la synchro VS Code <-> Studio.
- **Pattern :** Client-Server sécurisé.
  - *Server :* Gère l'état du plateau (Array 2D), les lancers de dés (RNG) et la validation des coups.
  - *Client :* Gère les Inputs (Cliquer sur une case), les animations (Tweening des figurines) et l'UI.
- **Data :** ModuleScript `UnitDatabase` contenant les stats et IDs des Assets.

## 4. Interface (UI)
- **Dice UI :** Interface 3D ou 2D montrant les dés roulant physiquement.
- **Inventory :** Bar en bas pour sélectionner les unités à placer.
- **Feedback :** "Hit Markers" et textes flottants "RIZZ!" ou "CRINGE!" selon les dégâts.

## 5. Monétisation (Ethical)
- **Monnaie :** "Rizz Coins" gagnés par partie.
- **Achats :** Skins pour les dés, déblocage d'unités "Legendary" (Gacha).
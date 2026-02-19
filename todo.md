# Brainrot Defense — Plan de Développement

> Chaque tâche est unitaire et testable immédiatement dans Roblox Studio.

---

## Phase 0 — Spawn Hub (Lobby)

### 0.1 — Construction du Spawn
- [x] **0.1.1** Ajouter les constantes du Spawn Hub dans `Constants.luau` : `SPAWN_CENTER`, `SPAWN_RADIUS`, `PORTALS` (données des 4 portails), `FOUNTAIN_*`.
  - ✅ *Test :* Require le module → `print(Constants.SPAWN_CENTER)` retourne le Vector3.
- [x] **0.1.2** Créer `src/server/SpawnBuilder.server.luau` : génère l'île circulaire d'herbe, la fontaine centrale (bassin + colonne + orbe + particules), les 4 portails (Jouer, Shop, Sell, Gacha), les chemins pavés, arbres, lampadaires, nuages.
  - ✅ *Test :* Play → île visible avec fontaine, 4 portails colorés (cyan, vert, jaune, violet), arbres et déco.
- [x] **0.1.3** Ambiance nocturne : éclairage à ClockTime=21, Bloom, ColorCorrection violette, atmosphère sombre.
  - ✅ *Test :* Play → ambiance nuit avec lueurs Neon très visibles.

### 0.2 — Système de Portails
- [x] **0.2.1** Créer `src/server/PortalSystem.server.luau` : détection Touched sur chaque portail. Portail "GameMap" téléporte vers la zone de jeu (mur de défense). Autres portails fire un RemoteEvent au client.
  - ✅ *Test :* Marcher dans le portail cyan → TP vers le mur. Marcher dans le portail vert → client reçoit "Shop".
- [x] **0.2.2** Créer le RemoteEvent `PortalEntered` via Rojo (`src/shared/Events/PortalEntered.model.json`).
  - ✅ *Test :* L'événement apparaît dans ReplicatedStorage.Shared.Events.
- [x] **0.2.3** Cooldown de 3 secondes sur les téléportations pour éviter les boucles.
  - ✅ *Test :* Traverser un portail 2x rapidement → seule la 1ère TP fonctionne.

### 0.3 — HUD du Spawn
- [x] **0.3.1** Créer `src/client/Controllers/SpawnHUD.client.luau` : message de bienvenue "BRAINROT DEFENSE" avec fade-out, compteur de Gems, bouton "Retour au Hub".
  - ✅ *Test :* Play → titre animé visible, Gems en haut à droite, bouton retour après TP.
- [x] **0.3.2** Popup contextuelle pour Shop / Sell / Gacha (placeholder "Bientôt disponible") avec animation tween in/out.
  - ✅ *Test :* Entrer dans un portail non-jeu → popup s'ouvre avec bouton Fermer.
- [x] **0.3.3** Créer `src/client/Controllers/SpawnCamera.client.luau` : caméra cinématique qui orbite autour du spawn pendant 5s puis rend le contrôle au joueur.
  - ✅ *Test :* Play → caméra tourne lentement autour de la fontaine, puis contrôle normal.

---

## Phase 1 — Setup Rojo & Grille (Data + Visuel)

### 1.0 — Infrastructure Rojo
- [ ] **1.0.1** Vérifier le `default.project.json` : s'assurer que `/src/server` → `ServerScriptService`, `/src/client` → `StarterPlayerScripts`, `/src/shared` → `ReplicatedStorage`.
  - ✅ *Test :* `rojo build` réussit sans erreur, le fichier `.rbxlx` s'ouvre dans Studio.
- [ ] **1.0.2** Créer l'arborescence de dossiers vides : `src/shared/Data/`, `src/shared/Systems/`, `src/server/Systems/`, `src/client/Systems/`, `src/client/UI/`.
  - ✅ *Test :* `rojo serve` → les dossiers apparaissent dans l'Explorer de Studio.

### 1.1 — Données de la Grille
- [ ] **1.1.1** Créer le ModuleScript `src/shared/Constants.luau` : définir `GRID_ROWS = 5`, `GRID_COLS = 9`, `TILE_SIZE`, `TILE_PADDING`, `GRID_ORIGIN` (Vector3).
  - ✅ *Test :* Require le module depuis la console Studio → les valeurs s'affichent correctement.
- [ ] **1.1.2** Créer le ModuleScript `src/shared/Data/UnitDatabase.luau` : définir les stats de base (Nom, Type, Rareté, Dés de défense) pour `SkibidiToilet` et `BasicZombie` uniquement.
  - ✅ *Test :* Require le module → `print(UnitDatabase.SkibidiToilet.Name)` retourne `"Skibidi Toilet"`.
- [ ] **1.1.3** Créer le ModuleScript `src/shared/Systems/BoardState.luau` : fonction `BoardState.new()` qui retourne un array 2D vide `[row][col] = nil` (5×9).
  - ✅ *Test :* `local board = BoardState.new(); print(#board, #board[1])` → `5  9`.

- [ ] **1.2.1** Créer le script serveur `src/server/Systems/GridSpawner.luau` : générer 45 Parts (5×9) en `Workspace` à partir de `Constants`. Chaque Part est un cube plat, ancrée, nommée `Tile_R{row}_C{col}`.
  - ✅ *Test :* Play → 45 tuiles visibles dans le monde 3D, bien alignées en grille.
- [ ] **1.2.2** Appliquer un code couleur aux zones : Colonnes 1-8 en vert clair ("Ohio Lawn"), Colonne 9 en rouge sombre ("Skibidi Street").
  - ✅ *Test :* Play → la colonne de droite est clairement rouge, le reste est vert.
- [ ] **1.2.3** Ajouter un `SurfaceGui` ou `BillboardGui` sur chaque tuile affichant ses coordonnées `(R, C)` en mode debug.
  - ✅ *Test :* ### 1.2 — Rendu Visuel de la Grille
Play → chaque tuile affiche son numéro (ex: "3,5").
- [ ] **1.2.4** Positionner la caméra dans un angle top-down/isométrique fixe pour voir toute la grille.
  - ✅ *Test :* Play → la grille entière est visible sans manipulation de caméra.

---

## Phase 2 — Core Loop (Machine à États + Dés)

### 2.0 — Machine à États (FSM)
- [ ] **2.0.1** Créer le ModuleScript `src/server/Systems/GameFSM.luau` : définir les états `WAITING`, `DICE_PHASE`, `SPAWN_PHASE`, `AUTO_MARCH`, `ACTION_PHASE`. Stocker `currentState`.
  - ✅ *Test :* Require → `print(GameFSM.currentState)` retourne `"WAITING"`.
- [ ] **2.0.2** Implémenter `GameFSM:TransitionTo(newState)` avec validation (transitions autorisées uniquement dans l'ordre défini). Utiliser `warn()` si transition invalide.
  - ✅ *Test :* `TransitionTo("DICE_PHASE")` → OK. `TransitionTo("ACTION_PHASE")` depuis `DICE_PHASE` → `warn` dans la console.
- [ ] **2.0.3** Créer un script serveur `src/server/GameLoop.luau` qui appelle `GameFSM:TransitionTo()` dans l'ordre complet d'un tour (DICE → SPAWN → MARCH → ACTION → DICE…) avec des `task.wait(2)` entre chaque.
  - ✅ *Test :* Play → la console affiche la séquence des états toutes les 2 secondes en boucle.

### 2.1 — Système de Dés
- [ ] **2.1.1** Créer le ModuleScript `src/shared/Systems/DiceRoller.luau` : fonction `DiceRoller.Roll(numDice: number): {number}` utilisant `Random.new()`. Retourne un tableau de résultats.
  - ✅ *Test :* `print(DiceRoller.Roll(2))` → deux valeurs entre 1 et 6.
- [ ] **2.1.2** Implémenter la logique d'allocation côté serveur : pendant `DICE_PHASE`, le serveur lance 2 dés et attend du client l'affectation (dé A → Renforts, dé B → Actions).
  - ✅ *Test :* Console serveur affiche les 2 dés et attend un signal client.
- [ ] **2.1.3** Créer le `RemoteEvent` `DiceResult` dans `ReplicatedStorage` (via Rojo) : le serveur fire les résultats au client.
  - ✅ *Test :* Client reçoit l'événement → `print` dans la console client les valeurs des dés.
- [ ] **2.1.4** Créer le `RemoteEvent` `DiceAllocation` : le client envoie son choix (quel dé va où). Le serveur valide que les valeurs matchent les dés lancés.
  - ✅ *Test :* Envoyer une allocation valide → serveur l'accepte. Envoyer une fausse → serveur `warn` et rejette.

---

## Phase 3 — Interaction (Placer des Unités)

### 3.0 — Raycasting & Sélection de Case
- [ ] **3.0.1** Créer `src/client/Systems/TileSelector.luau` : au clic souris, envoyer un Raycast depuis la caméra. Identifier la tuile touchée via son nom `Tile_R{row}_C{col}`.
  - ✅ *Test :* Cliquer sur une tuile → `print` dans la console client ses coordonnées `(row, col)`.
- [ ] **3.0.2** Ajouter un feedback visuel : la tuile survolée (Raycast continu) change de couleur (highlight jaune). Retour à la couleur normale quand on quitte.
  - ✅ *Test :* Déplacer la souris sur la grille → la tuile sous le curseur s'illumine.
- [ ] **3.0.3** Ajouter un feedback de clic : la tuile sélectionnée fait un petit `TweenService` bounce (scale up puis retour).
  - ✅ *Test :* Cliquer → la tuile rebondit brièvement.

### 3.1 — Placement d'Unités
- [ ] **3.1.1** Créer le `RemoteEvent` `PlaceUnit` : le client envoie `(unitId, row, col)`, le serveur valide (case vide ? zone correcte col 1-8 ? budget suffisant ?).
  - ✅ *Test :* Envoyer une requête valide → serveur `print("Placement OK")`. Case occupée → serveur rejette.
- [ ] **3.1.2** Côté serveur, mettre à jour le `BoardState` : `board[row][col] = { unitId = "SkibidiToilet", owner = player }`.
  - ✅ *Test :* Après placement, `print(board[row][col].unitId)` → `"SkibidiToilet"`.
- [ ] **3.1.3** Côté serveur, spawner un modèle 3D placeholder (Part colorée ou MeshPart simple) sur la tuile correspondante quand le `BoardState` est modifié.
  - ✅ *Test :* Placer une unité → un cube bleu apparaît sur la tuile dans le monde 3D.
- [ ] **3.1.4** Connecter le placement au flux FSM : le placement n'est autorisé que pendant `SPAWN_PHASE`. Toute requête hors de cette phase est rejetée.
  - ✅ *Test :* Essayer de placer pendant `AUTO_MARCH` → rejeté. Pendant `SPAWN_PHASE` → accepté.

### 3.2 — Inventaire / Barre d'Unités (UI)
- [ ] **3.2.1** Créer `src/client/UI/UnitBar.luau` : un `ScreenGui` avec une barre horizontale en bas contenant des boutons (un par unité disponible). Utiliser `Scale` pour le sizing.
  - ✅ *Test :* Play → la barre apparaît en bas de l'écran avec des boutons.
- [ ] **3.2.2** Implémenter la sélection d'unité : cliquer sur un bouton de la barre → stocker `selectedUnitId` côté client. Le bouton sélectionné change de couleur.
  - ✅ *Test :* Cliquer "Skibidi" → bouton surligné, `print(selectedUnitId)` → `"SkibidiToilet"`.
- [ ] **3.2.3** Connecter le flux complet : sélectionner une unité dans la barre → cliquer une tuile → fire `PlaceUnit` avec les données.
  - ✅ *Test :* Sélectionner + cliquer tuile → unité apparaît sur la grille.

---

## Phase 4 — Logique Zombies (Mouvement Auto)

### 4.0 — Spawn des Zombies
- [ ] **4.0.1** Créer `src/server/Systems/ZombieSpawner.luau` : à chaque tour, spawner un `BasicZombie` sur une case aléatoire de la colonne 9 (si vide). Mettre à jour le `BoardState`.
  - ✅ *Test :* Après un tour → un placeholder zombie (Part rouge) apparaît en colonne 9.
- [ ] **4.0.2** Ajouter une logique de vague : le nombre de zombies spawnés augmente tous les 3 tours (1, puis 2, puis 3…).
  - ✅ *Test :* Tour 1 → 1 zombie. Tour 4 → 2 zombies. Vérifiable via `print`.

### 4.1 — Déplacement Automatique (Auto-March)
- [ ] **4.1.1** Créer `src/server/Systems/AutoMarch.luau` : pendant `AUTO_MARCH`, itérer sur le `BoardState`, déplacer chaque zombie d'une colonne vers la gauche. Mettre à jour l'array 2D.
  - ✅ *Test :* Zombie en `(3, 9)` → après Auto-March → `board[3][8]` contient le zombie, `board[3][9]` est `nil`.
- [ ] **4.1.2** Gérer le cas "fin de grille" : si un zombie atteint la colonne 0 (hors grille), retirer du board et `print("GAME OVER - Zombie passed!")`.
  - ✅ *Test :* Zombie en col 1 → Auto-March → message "GAME OVER" dans la console.
- [ ] **4.1.3** Animer le déplacement côté client : quand le serveur notifie un mouvement (via `RemoteEvent` `BoardUpdate`), le client tween le modèle 3D du zombie vers sa nouvelle position.
  - ✅ *Test :* Le zombie glisse visuellement d'une case vers la gauche (pas de téléportation).

### 4.2 — Zombie Spécial : Nike Shark
- [ ] **4.2.1** Ajouter `NikeShark` dans `UnitDatabase` avec la propriété `moveSpeed = 2`.
  - ✅ *Test :* `print(UnitDatabase.NikeShark.moveSpeed)` → `2`.
- [ ] **4.2.2** Modifier `AutoMarch` pour lire `moveSpeed` depuis `UnitDatabase` et déplacer de N cases au lieu de 1.
  - ✅ *Test :* Nike Shark en col 9 → après march → col 7 (sauté 2 cases).

---

## Phase 5 — Combat & UI

### 5.0 — Détection de Collision
- [ ] **5.0.1** Dans `AutoMarch`, détecter quand un zombie entre dans une case occupée par une unité Brainrot. Stocker la collision : `{zombie, defender, row, col}`.
  - ✅ *Test :* Zombie arrive sur case avec Skibidi → `print("Collision détectée en (R, C)")`.

### 5.1 — Résolution de Combat (Dés)
- [ ] **5.1.1** Créer `src/server/Systems/CombatResolver.luau` : fonction `Resolve(zombie, defender)` → lancer des dés de défense (nombre = stat `defenseDice` de l'unité). Si résultat ≥ seuil → zombie tué. Sinon → défenseur mangé.
  - ✅ *Test :* Appeler `Resolve()` manuellement → `print("Zombie killed")` ou `print("Defender eaten")` selon le jet.
- [ ] **5.1.2** Appliquer le résultat au `BoardState` : retirer l'unité perdante du tableau 2D.
  - ✅ *Test :* Après combat → vérifier que `board[row][col]` ne contient plus que le survivant ou est `nil`.
- [ ] **5.1.3** Détruire le modèle 3D de l'unité perdante côté serveur (nettoyage Workspace).
  - ✅ *Test :* Après combat → le modèle du perdant disparaît de la scène.

### 5.2 — Animations & Feedback Combat
- [ ] **5.2.1** Créer `src/client/Systems/CombatFX.luau` : à réception d'un `RemoteEvent` `CombatResult`, jouer un tween de "shake" sur l'unité attaquée.
  - ✅ *Test :* Combat → l'unité tremble brièvement avant de disparaître.
- [ ] **5.2.2** Ajouter un texte flottant (`BillboardGui`) "RIZZ!" (si défenseur gagne) ou "CRINGE!" (si zombie gagne) au-dessus de la case.
  - ✅ *Test :* Combat → un texte apparaît, monte et disparaît en fondu.
- [ ] **5.2.3** Ajouter un effet particule (Explosion simple ou étoiles) lors de la destruction d'une unité.
  - ✅ *Test :* Unité détruite → burst de particules visible.

### 5.3 — Phase d'Action (Capacités Spéciales)
- [ ] **5.3.1** Implémenter l'action de base côté serveur : pendant `ACTION_PHASE`, le joueur peut dépenser ses points d'action pour faire attaquer une unité Brainrot sur la case adjacente à droite.
  - ✅ *Test :* Skibidi en `(3, 4)`, zombie en `(3, 5)` → action → combat déclenché.
- [ ] **5.3.2** Créer le `RemoteEvent` `UseAction` : le client envoie `(row, col)` de l'unité à activer. Le serveur valide (phase correcte ? points suffisants ? unité présente ?).
  - ✅ *Test :* Envoyer action valide → combat. Hors phase → rejeté.
- [ ] **5.3.3** Ajouter `Gigachad` dans `UnitDatabase` avec capacité "Zone Damage" (attaque 3 cases devant lui).
  - ✅ *Test :* Gigachad en `(3, 2)` → action → combat sur `(3, 3)`, `(3, 4)`, `(3, 5)`.

### 5.4 — UI Principale (HUD)
- [ ] **5.4.1** Créer `src/client/UI/DiceUI.luau` : afficher les 2 dés résultats à l'écran avec des ImageLabels ou TextLabels géants. Tween d'apparition (scale bounce).
  - ✅ *Test :* Phase de dés → deux gros chiffres apparaissent à l'écran avec animation.
- [ ] **5.4.2** Ajouter les boutons d'allocation : "Ce dé → Renforts" / "Ce dé → Actions" sous chaque dé. Au clic → fire `DiceAllocation`.
  - ✅ *Test :* Cliquer un bouton → les dés sont assignés, UI se ferme, `SPAWN_PHASE` commence.
- [ ] **5.4.3** Créer `src/client/UI/TurnHUD.luau` : bandeau en haut affichant la phase actuelle (`DICE PHASE`, `SPAWN PHASE`…) et le numéro du tour.
  - ✅ *Test :* Play → le bandeau change de texte à chaque transition de phase.
- [ ] **5.4.4** Afficher les points de Renforts et d'Actions restants dans le HUD pendant les phases correspondantes.
  - ✅ *Test :* Placer une unité → le compteur de Renforts décrémente visuellement.

### 5.5 — Condition de Victoire / Défaite
- [ ] **5.5.1** Implémenter la condition de défaite : si un zombie franchit la colonne 1, afficher un écran "GAME OVER" (ScreenGui plein écran rouge avec texte).
  - ✅ *Test :* Zombie passe → écran rouge "GAME OVER" visible.
- [ ] **5.5.2** Implémenter la condition de victoire : survivre N tours (ex: 10). Afficher un écran "YOU SURVIVED! +100 Rizz Coins".
  - ✅ *Test :* Atteindre le tour 10 → écran de victoire visible.
- [ ] **5.5.3** Ajouter un bouton "Rejouer" sur les écrans de fin qui reset le `BoardState`, nettoie le Workspace et relance la FSM.
  - ✅ *Test :* Cliquer "Rejouer" → grille nettoyée, nouveau tour commence.

---

## Récapitulatif

| Phase | Nb Tâches | Focus |
|-------|-----------|-------|
| 1 — Setup & Grille | 7 | Fondations, données, rendu de la grille |
| 2 — Core Loop | 7 | FSM, dés, RemoteEvents |
| 3 — Interaction | 9 | Raycasting, placement, UI inventaire |
| 4 — Zombies | 6 | Spawn, mouvement auto, types spéciaux |
| 5 — Combat & UI | 16 | Résolution combat, FX, HUD, fin de partie |
| **Total** | **45** | |

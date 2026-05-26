# JAM Mini Launcher
This is the game launcher for the JAM Mini.  
It is a simple game launcher for Stevens Game Development club's games.  
The JAM Mini itself is a small, portable machine that will be put into the UCC Game Room for anyone to use.  
The specs and details of the machine have yet to be determined.

# Game Library Structure (can change based on specific device this is used on):
```
|__ /
   |__ Users
	  |__ sgdcuser
		 |__ MiniLauncher.app
		 |__ games
			|__ game1
			   |__ Game1.app
			   |__ game1.json
			   |__ game1.ogv
			   |__ game1.png
			|__ game2
			   |__ Game2.app
			   |__ game2.json
			   |__ game2.ogv
			   |__ game2.png   
```

# Json structure:
```json
{
  "name": "Game Name",
  "author": "Author Name",
  "description": "Game Description",
  "genres": "Genre1-Genre2-Genre3",
  "type": "# of players",
  "creation_year": "Year Created",
  "grad_year": "Year Graduated",
}
```

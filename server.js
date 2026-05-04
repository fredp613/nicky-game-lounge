const express = require('express');
const { engine } = require('express-handlebars');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Handlebars setup
app.engine('hbs', engine({
    extname: '.hbs',
    defaultLayout: 'main',
    layoutsDir: path.join(__dirname, 'views/layouts'),
    helpers: {
        eq: (a, b) => a === b
    }
}));
app.set('view engine', 'hbs');
app.set('views', path.join(__dirname, 'views'));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Games data
const games = [
    {
        id: 'flappy-luigi',
        title: 'Flappy Luigi',
        description: 'Help Luigi fly through the pipes! Tap or press your key to flap.',
        url: '/games/flappy-luigi.html',
        color: '#4CAF50',
        icon: 'mushroom',
        tag: 'Arcade',
        difficulty: 'Easy–Hard'
    },
    {
        id: 'global-command-1942',
        title: 'Global Command 1942',
        description: 'Command a globe-scale WWII strategy board with country strength, terrain zoom, and stacked pieces.',
        url: '/games/aaa.html',
        color: '#4F9CF9',
        icon: 'globe',
        tag: 'Strategy',
        difficulty: 'Medium–Expert'
    },
    {
        id: 'nicky-card-games',
        title: "Nicky's Card Games",
        description: "Five casino card games in one — Texas Hold'Em, Baccarat, 3-Card Poker, Solitaire, and Cinq Cents 500. Supports up to 4 human players on one device.",
        url: '/games/nicky-card-games.html',
        color: '#e8b84b',
        icon: 'cards',
        tag: 'Casino',
        difficulty: 'Easy–Expert'
    },
    {
        id: 'chess',
        title: 'Royal Chess',
        description: 'Play chess against a friend or the computer. Choose your strategy, get move suggestions, and battle with gold & silver pieces on a glass board.',
        url: '/games/chess.html',
        color: '#e8b84b',
        icon: 'chess',
        tag: 'Strategy',
        difficulty: 'Easy–Expert'
    },
    {
        id: 'checkers',
        title: 'Royal Checkers',
        description: 'Classic checkers with gold & silver pieces. Play 2-player or vs AI with strategy coaching, multi-jump combos, and an optional timer.',
        url: '/games/checkers.html',
        color: '#c8d4e0',
        icon: 'checkers',
        tag: 'Strategy',
        difficulty: 'Easy–Expert'
    },
    {
        id: 'triple-tile',
        title: 'Triple Cascade',
        description: 'Tap layered tiles into the zone — match 3 to clear them before all 7 slots fill up!',
        url: '/games/triple-tile.html',
        color: '#f97316',
        icon: 'tiles',
        tag: 'Puzzle',
        difficulty: 'Easy–Hard'
    },
    {
        id: 'snowball-fight',
        title: "Nicky's Snowball Fight",
        description: 'Build snow walls, dodge lobs & eliminate snowmen in an epic winter battle!',
        url: '/games/snowball-fight.html',
        color: '#42A5F5',
        icon: 'snowflake',
        tag: 'Action',
        difficulty: 'Easy–Hard'
    },
    {
        id: 'maple-run',
        title: 'Maple Run',
        description: 'Run through the autumn forest collecting maple leaves & dodging obstacles!',
        url: '/games/maple-run.html',
        color: '#EF5350',
        icon: 'leaf',
        tag: 'Endless Runner',
        difficulty: 'Easy–Hard'
    },
    {
        id: 'snake-luigi',
        title: 'Snake Luigi',
        description: 'Guide Luigi the snake — collect coins, mushrooms & stars without hitting the walls!',
        url: '/games/snake-luigi.html',
        color: '#2ecc40',
        icon: 'snake',
        tag: 'Classic',
        difficulty: 'Easy–Hard'
    },
    {
        id: 'pong-luigi',
        title: 'Pong Luigi',
        description: 'Face off against CPU Bowser in a retro paddle battle — first to 7 wins!',
        url: '/games/pong-luigi.html',
        color: '#f9ca24',
        icon: 'pong',
        tag: 'Classic',
        difficulty: 'Easy–Hard'
    },
    {
        id: 'pac-luigi',
        title: 'Pac Luigi',
        description: 'Chomp through the maze, eat power pellets & outsmart the ghosts to clear every level!',
        url: '/games/pac-luigi.html',
        color: '#ff9800',
        icon: 'pacman',
        tag: 'Classic',
        difficulty: 'Easy–Hard'
    },
    {
        id: 'luigi-dash',
        title: 'Luigi Dash',
        description: 'Jump, double-jump & fly through obstacles — reach 100% without hitting a single spike!',
        url: '/games/luigi-dash.html',
        color: '#a855f7',
        icon: 'dash',
        tag: 'Rhythm Runner',
        difficulty: 'Hard'
    },
    {
        id: 'tetris-luigi',
        title: 'Tetris Luigi',
        description: 'Stack blocks, clear lines & survive as long as you can in this classic puzzle game!',
        url: '/games/tetris-luigi.html',
        color: '#00ccff',
        icon: 'tetris',
        tag: 'Puzzle',
        difficulty: 'Easy–Hard'
    }
];

// Routes
app.get('/', (req, res) => {
    res.render('home', {
        title: "Nicky's Game Lounge",
        games
    });
});

app.listen(PORT, () => {
    console.log(`🎮 Nicky's Game Lounge is live at http://localhost:${PORT}`);
});
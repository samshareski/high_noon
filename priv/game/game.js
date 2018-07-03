// the game itself
var game;
var soundManager;
var currentGameState = undefined;
var currentPlayer;
var canPoke = true;
var canvas;

// global game options
var gameOptions = {
    cloudSpeed: 0.2,
    tumbleweedSpin: 1,
    tumbleweedSpeed: 1
}

const registerForm = document.querySelector('.register')
const username = document.querySelector('.name-input')
username.value = JSON.parse(localStorage.getItem('user'));
registerForm.addEventListener('submit', event => {
    event.preventDefault()
    registerPlayer(event.target['0'].value)
    canvas.style.display = 'initial';
    canPoke = true;
    registerForm.remove()
})
  
function registerPlayer(name) {
    window.playerName = name
    const socket = new WebSocket(getWebSocketURI())
    socket.onmessage = onMessage
    socket.onclose = onClose

    socket.onopen = ev => socket.send(`name:${name}`)

    document.addEventListener('click', _ => pokeWebSocket(socket))
    document.addEventListener('touchstart', _ => pokeWebSocket(socket))
    document.addEventListener('keydown', _ => pokeWebSocket(socket))
    localStorage.setItem('user', JSON.stringify(name));
}

function getWebSocketURI() {
    const loc = window.location
    const wsProtocol = loc.protocol === 'https:' ? 'wss:' : 'ws:'
    return `${wsProtocol}//${loc.host}/ws`
}

function pokeWebSocket(socket) {
    if(canPoke){
        socket.send('poke')
    }
}

function onMessage(msg) {
    let data
    try {
        data = JSON.parse(msg.data)
        console.log(data)
    } catch (e) {
        console.error('Failed to parse WS message')
        console.error(msg)
        return
    }

    RESPONSE_FUNCTIONS[data.type](data)
}

function onClose(msg) {
    console.log('WebSocket closed')
    game.scene.scenes[0].resetScene()
}

function onDisconnect(_) {
    console.log('Disconnected')
    game.scene.scenes[0].disconnected();
}

function onSearching() {
    game.scene.scenes[0].resetScene();
    game.scene.scenes[0].searching();
}

function onOpponentLeft(_) {
    console.log('Opponent Left')
    game.scene.scenes[0].opponentLeft();
  }

function onJoin({ game_roster }) {
  console.log('game roster', game_roster)
  console.log('game', game)
  currentPlayer = game_roster.assignment
  game.scene.scenes[0].joined();
  game.scene.scenes[0].setPlayers(game_roster.player_1, game_roster.player_2)

}

var player1Backfired = false
var player2Backfired = false

function onGameUpdate({ game_readiness, game_state }) {
    if (!game_state.started) {
        if(game_readiness.player_1_ready){
            console.log('player 1 ready')
            if(currentPlayer ===  'player_1'){
                game.scene.scenes[0].waiting();
            }
        }
        
        if(game_readiness.player_2_ready){
            if(currentPlayer ===  'player_2'){
                game.scene.scenes[0].waiting();
            }
        }
    }else{
        if(!currentGameState.high_noon && game_state.high_noon){
            game.scene.scenes[0].highNoon();
        }

        if(!currentGameState.started && game_state.started){
            game.scene.scenes[0].ready();
        }
    
        switch (game_state.player_1_status) {
            case 'fine':
                break
            case 'backfired':
                if(!player1Backfired){
                    game.scene.scenes[0].player1Backfire();
                    player1Backfired = true
                }
                break
            case 'shot':
                game.scene.scenes[0].player1Die();
                game.scene.scenes[0].player2Shoot();
                break
        }
    
        switch (game_state.player_2_status) {
            case 'fine':
                break
            case 'backfired':
                if(!player2Backfired){
                    game.scene.scenes[0].player2Backfire();
                    player2Backfired = true
                }
                break
            case 'shot':
                game.scene.scenes[0].player2Die();
                game.scene.scenes[0].player1Shoot();
                break
        }

        if (game_state.winner !== null) {
            canPoke = false;
            setTimeout(
            function() {
                game.scene.scenes[0].finished();
                canPoke = true;
            }, 5000);

            if (game_state.winner === 'draw') {
                game.scene.scenes[0].draw();
            } else if (game_state.winner === window.currentPlayer) {
                game.scene.scenes[0].youWin();
            } else {
                game.scene.scenes[0].youLose();
            }
        }
    }

    currentGameState = game_state;
}

const RESPONSE_FUNCTIONS = {
    searching: onSearching,
    joined_game: onJoin,
    game_update: onGameUpdate,
    disconnected: onDisconnect,
    opponent_left: onOpponentLeft
}

setTimeout(function() { window.scrollTo(0, 1) }, 100);

// once the window loads...
window.onload = function() {
    loadGame();
    canPoke= false;
    canvas = document.querySelector('canvas')
    canvas.style.display = 'none';
}

const loadGame = function () {
    // game configuration object
    var gameConfig = {

        // render type
        type: Phaser.CANVAS,

        // game width, in pixels
        width: 1920,

        // game height, in pixels
        height: 1080,

        // game background color
        backgroundColor: 0xffffff,

        // scenes used by the game
        scene: [playGame]
    };

    // game constructor
    game = new Phaser.Game(gameConfig);

    // pure javascript to give focus to the page/frame and scale the game
    window.focus()
    resize();
    window.addEventListener("resize", resize, false);
}

// PlayGame scene
class playGame extends Phaser.Scene{

    // constructor
    constructor(){
        super("PlayGame");
    }

    // method to be executed when the scene preloads
    preload(){
        // loading assets
        this.load.image("background", "/assets/background.png");
        this.load.image("buildings", "/assets/buildings.png");
        this.load.image("cloud1", "/assets/cloud1.png");
        this.load.image("cloud2", "/assets/cloud2.png");
        this.load.image("cloud3", "/assets/cloud3.png");
        this.load.image("tumbleweed", "/assets/tumbleweed.png");
        this.load.image("hourHand", "/assets/hour.png");
        this.load.image("minuteHand", "/assets/minute.png");
        
        this.load.spritesheet('player_idle', '/assets/idle_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 30});
        this.load.spritesheet('player_shoot', '/assets/shoot_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 17});
        this.load.spritesheet('player_backfire', '/assets/shoot_fail_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 15});
        this.load.spritesheet('player_die', '/assets/die_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 21});

        // this.load.audio("wind", "/assets/sounds/wind.mp3");
        // this.load.audio("tumbleweedSound", "/assets/sounds/tumbleweed.mp3");

    }

    // method to be executed once the scene has been created
    create(){

        this.anims.create({
            key: 'idle',
            frames: this.anims.generateFrameNumbers('player_idle', {
                start: 0,
                end: 29
            }),
            repeat: -1,
            frameRate: 20
        });

        this.anims.create({
            key: 'shoot',
            frames: this.anims.generateFrameNumbers('player_shoot', {
                start: 0,
                end: 16
            }),
            repeat: 0,
            frameRate: 20
        });

        this.anims.create({
            key: 'backfire',
            frames: this.anims.generateFrameNumbers('player_backfire', {
                start: 0,
                end: 14
            }),
            repeat: 0,
            frameRate: 20
        });

        this.anims.create({
            key: 'die',
            frames: this.anims.generateFrameNumbers('player_die', {
                start: 0,
                end: 20
            }),
            repeat: 0,
            frameRate: 20
        });

        // can the player shoot? Yes, at the beginning of the game
        this.canShoot = true;
        this.canTumbleweed = true;
        this.tumbleweedMoving = false;

        // group to store all rotating knives
        this.cloudGroup = this.add.group();

        this.background = this.add.sprite(game.config.width / 2, game.config.height / 2, "background");
        this.buildings = this.add.sprite(game.config.width / 2, game.config.height / 2, "buildings");
        this.buildings.depth = 1;

        this.minuteHand = this.add.sprite(game.config.width / 2.02, game.config.height / 3.42, "minuteHand");
        this.hourHand = this.add.sprite(game.config.width / 2.02, game.config.height / 3.8, "hourHand");
        this.minuteHand.depth = 1;
        this.hourHand.depth = 1;
        this.minuteHand.setOrigin(0.5,0.93);

        this.minuteHand.rotation -= 0.2;

        this.cloudGroup.add(this.add.sprite(game.config.width / 6, game.config.height / 5, "cloud1"));
        this.cloudGroup.add(this.add.sprite(game.config.width / 2, game.config.height / 4, "cloud2"));
        this.cloudGroup.add(this.add.sprite(game.config.width / 1.2, game.config.height / 7, "cloud3"));

        // this.wind = this.sound.add("wind", {volume: 0.15, loop: true})
        // this.wind.play();

        this.status = this.add.text(game.config.width / 2, game.config.height / 2, "", { font: "bold 64px texas", fill: '#0a0a0a'});
        this.status.setOrigin(0.5,0)
        this.status.depth = 6;

        this.subText = this.add.text(game.config.width / 2, game.config.height / 1.8, "", { font: "bold 32px texas", fill: '#1b1b1b'});
        this.subText.setOrigin(0.5,0)
        this.subText.depth = 6;
    }

    draw(){
        this.status.setText("Draw!");
        this.status.alpha = 0;
        this.add.tween({targets: this.status, ease: 'Linear', duration: 600,  alpha: 1})
    }

    youWin(){
        this.status.setText("You Win!");
        this.status.alpha = 0;
        this.add.tween({targets: this.status, ease: 'Linear', duration: 600,  alpha: 1})
    }

    youLose(){
        this.status.setText("You Lose");
        this.status.alpha = 0;
        this.add.tween({targets: this.status, ease: 'Linear', duration: 600, alpha: 1})
    }

    finished() {
        this.subText.setText("click to search for new game");
        this.subText.alpha = 0;
        this.add.tween({targets: this.subText, ease: 'Linear', duration: 600, alpha: 1})
    }

    searching() {
        this.status.alpha = 1;
        this.status.setText("Searching");
    }

    joined() {
        this.status.alpha = 1;
        this.status.setText("Click to Ready");
    }

    waiting() {
        this.status.alpha = 1;
        this.status.setText("Waiting for other player");
    }

    ready() {
        this.status.setText("^ Shoot at Noon ^");
        this.status.alpha = 1;
        setTimeout(
        () => {
            this.add.tween({targets: this.status, ease: 'Linear', duration: 800, alpha: 0})
        }, 600);
    }

    disconnected() {
        this.resetScene();
        this.status.setText('Disconnected')
        this.subText.setText("click to search for new game");
    }

    opponentLeft() {
        this.resetScene();
        this.status.setText('Opponent Ran')
        this.subText.setText("click to search for new game");
    }

    clearText(){
        this.status.setText("");
        this.subText.setText("");
    }

    resetScene(){
        if(this.player1){
            this.player1.destroy();
            this.player1Name.destroy();
            this.player2.destroy();
            this.player2Name.destroy();
            this.minuteHand.rotation = -0.2;
        }
        this.clearText();
    }

    setPlayers(player1, player2){
        this.setPlayer1(player1);
        this.setPlayer2(player2);
    }

    setPlayer1(name){
        this.player1 = this.add.sprite(game.config.width / 3.5, game.config.height / 1.4, 'idle');
        this.player1.anims.play('idle');
        this.player1.depth = 3;
        this.player1Name = this.add.text(16, game.config.height / 1.1, currentPlayer === 'player_1' ? name + ' *' : name, { font: "bold 50px texas", fill: '#0a0a0a'});
        this.player1Name.depth = 5;
    }

    setPlayer2(name){
        this.player2 = this.add.sprite(game.config.width / 1.4, game.config.height / 1.4, "idle");
        this.player2.anims.play('idle');
        this.player2.depth = 3;
        this.player2.scaleX = -1
        this.player2Name = this.add.text(game.config.width / 1.02, game.config.height / 1.1, currentPlayer === 'player_2' ? '* ' + name : name, { font: "bold 50px texas", fill: '#0a0a0a'});
        this.player2Name.x -= (this.player2Name.width);
        this.player2Name.depth = 5;
    }

    player1Die(){
        this.player1.anims.play('die');
    }

    player1Shoot(){
        this.player1.anims.play('shoot');
    }

    player1Backfire(){
        this.player1.anims.play('backfire');
    }

    player2Die(){
        this.player2.anims.play('die');
    }

    player2Shoot(){
        this.player2.anims.play('shoot');
    }

    player2Backfire(){
        this.player2.anims.play('backfire');
    }

    highNoon(){
        this.add.tween({targets: this.minuteHand, ease: 'Bounce', duration: 200, delay: 0, angle: 0})
    }

    startTumbleWeed(){
        if(this.canTumbleweed){
            this.canTumbleweed = false;
            this.tumbleweedMoving = true;

            this.tumbleweed = this.add.sprite(-110, game.config.height / 1.4, "tumbleweed");
            this.tumbleweed.depth = 2;

            // this.tumbleweedSound = this.sound.add("tumbleweedSound", { volume: 0.05, loop: true })
            // this.tumbleweedSound.play();
        }
    }

    stopTumbleWeed(){
        this.tumbleweedMoving = false;
        this.canTumbleweed = true;
        this.tumbleweed.destroy();
        // var fadeAudio = setInterval(() => {
        //     if(this.tumbleweedSound.volume <= 0){
        //         clearInterval(fadeAudio);
        //         this.tumbleweedSound.stop();
        //     }
        //     this.tumbleweedSound.volume -= 0.01;
        // }, 200);
    }

    // method to be executed at each frame
    update(){
        //getting an array with all clouds
        var clouds = this.cloudGroup.getChildren();

        // looping through rotating knives
        for (var i = 0; i < clouds.length; i++){

            //move clouds
            if(clouds[i].x > game.config.width / 1.2){
                clouds[i].x = -10;
            }else{
                clouds[i].x += gameOptions.cloudSpeed;
            }
        }

        if(this.tumbleweedMoving){
            this.tumbleweed.angle += gameOptions.tumbleweedSpin;
            this.tumbleweed.x += gameOptions.tumbleweedSpeed;
            this.tumbleweed.y += Math.sin(this.time.now / 300) / 2;

            if(this.tumbleweed.x > game.config.width + 100){
                this.stopTumbleWeed();
            }
        }else{
            var num = getRandomInt(1000);
            if(num == 13){
                this.startTumbleWeed();
            }
        }
    }
}

function getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
}

// pure javascript to scale the game
function resize() {
    var canvas = document.querySelector("canvas");
    var windowWidth = window.innerWidth;
    var windowHeight = window.innerHeight;
    var windowRatio = windowWidth / windowHeight;
    var gameRatio = game.config.width / game.config.height;
    if(windowRatio < gameRatio){
        canvas.style.width = windowWidth + "px";
        canvas.style.height = (windowWidth / gameRatio ) + "px";
    }
    else{
        canvas.style.width = (windowHeight * gameRatio) + "px";
        canvas.style.height = windowHeight + "px";
    }
}


// the game itself
var game;
var soundManager;
var currentGameState = undefined;

// global game options
var gameOptions = {
    cloudSpeed: 0.2,
    tumbleweedSpin: 1,
    tumbleweedSpeed: 1
}

const registerForm = document.querySelector('.register')
registerForm.addEventListener('submit', event => {
    event.preventDefault()

    registerPlayer(event.target['0'].value)

    registerForm.remove()
})
  
function registerPlayer(name) {
    window.playerName = name
    const socket = new WebSocket(getWebSocketURI())
    socket.onmessage = onMessage
    socket.onclose = onClose

    socket.onopen = ev => socket.send(`name:${name}`)

    document.addEventListener('click', _ => pokeWebSocket(socket))
    document.addEventListener('keydown', _ => pokeWebSocket(socket))

}

function getWebSocketURI() {
    const loc = window.location
    const wsProtocol = loc.protocol === 'https:' ? 'wss:' : 'ws:'
    return `${wsProtocol}//${loc.host}/ws`
}

function pokeWebSocket(socket) {
    socket.send('poke')
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
    game.scene.scenes[0].resetScene()
}

function onSearching() {
  console.log('searching1')
}

function onJoin({ game_roster }) {
  console.log('game roster', game_roster)
  console.log('game', game)
  game.scene.scenes[0].setPlayers(game_roster.player_1, game_roster.player_2)

}

var player1Backfired = false
var player2Backfired = false

function onGameUpdate({ game_readiness, game_state }) {

    if(currentGameState != undefined && !currentGameState.high_noon && game_state.high_noon){
        game.scene.scenes[0].highNoon();
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

    currentGameState = game_state;
}
  


const RESPONSE_FUNCTIONS = {
    searching: onSearching,
    joined_game: onJoin,
    game_update: onGameUpdate,
    disconnected: onDisconnect,
}

setTimeout(function() { window.scrollTo(0, 1) }, 100);

// once the window loads...
window.onload = function() {

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
        this.load.image("background", "game/assets/background.png");
        this.load.image("buildings", "game/assets/buildings.png");
        this.load.image("cloud1", "game/assets/cloud1.png");
        this.load.image("cloud2", "game/assets/cloud2.png");
        this.load.image("cloud3", "game/assets/cloud3.png");
        this.load.image("tumbleweed", "game/assets/tumbleweed.png");
        this.load.image("hourHand", "game/assets/hour.png");
        this.load.image("minuteHand", "game/assets/minute.png");
        
        this.load.spritesheet('player_idle', 'game/assets/idle_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 30});
        this.load.spritesheet('player_shoot', 'game/assets/shoot_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 17});
        this.load.spritesheet('player_backfire', 'game/assets/shoot_fail_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 15});
        this.load.spritesheet('player_die', 'game/assets/die_spritesheet.png', {frameWidth: 400, frameHeight: 400, endFrame: 21});

        // game.load.spritesheet('mummy', 'assets/sprites/metalslug_mummy37x45.png', 37, 45, 18);

        this.load.audio("wind", "game/assets/sounds/wind.mp3");
        this.load.audio("tumbleweedSound", "game/assets/sounds/tumbleweed.mp3");

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
        this.isHighNoon = false;

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

        this.wind = this.sound.add("wind", { volume: 0.15, loop: true})
        this.wind.play();

        // waiting for player input to shoot
        // this.input.on("pointerdown", this.shoot, this);
    }

    resetScene(){
        this.player1.destroy();
        this.player1Name.destroy();
        this.player2.destroy();
        this.player2Name.destroy();
    }

    setPlayers(player1, player2){
        this.setPlayer1(player1);
        this.setPlayer2(player2);
    }

    setPlayer1(name){
        this.player1 = this.add.sprite(game.config.width / 3.5, game.config.height / 1.4, 'idle');
        this.player1.anims.play('idle');
        this.player1.depth = 3;
        this.player1Name = this.add.text(16, game.config.height / 1.1, name, { font: "bold 64px Arial", fill: '#000'});
        this.player1Name.depth = 5;
    }

    setPlayer2(name){
        this.player2 = this.add.sprite(game.config.width / 1.4, game.config.height / 1.4, "idle");
        this.player2.anims.play('idle');
        this.player2.depth = 3;
        this.player2.scaleX = -1
        this.player2Name = this.add.text(game.config.width / 1.02, game.config.height / 1.1, name, { font: "bold 64px Arial", fill: '#000'});
        this.player2Name.x -= (this.player2Name.width);
        this.player2Name.depth = 5;
    }

    // method to shoot
    // shoot(){
    //     // can the player shoot?
    //     if(this.canShoot){

    //         // player can't shoot anymore
    //         this.canShoot = false;
    //         console.log('pew pew');
    //         socket.send('poke')
    //     }
    // }

    player1Die(){
        this.player1.anims.play('die')
    }

    player1Shoot(){
        this.player1.anims.play('shoot')
    }

    player1Backfire(){
        this.player1.anims.play('backfire')
    }

    player2Die(){
        this.player2.anims.play('die')
    }

    player2Shoot(){
        this.player2.anims.play('shoot')
    }

    player2Backfire(){
        this.player2.anims.play('backfire')
    }

    highNoon(){
        this.isHighNoon = true;
        this.add.tween({targets: this.minuteHand, ease: 'Bounce', duration: 200, delay: 0, angle: 0})
    }

    startTumbleWeed(){
        if(this.canTumbleweed){
            this.canTumbleweed = false;
            this.tumbleweedMoving = true;

            this.tumbleweed = this.add.sprite(-110, game.config.height / 1.4, "tumbleweed");
            this.tumbleweed.depth = 2;

            this.tumbleweedSound = this.sound.add("tumbleweedSound", { volume: 0.05, loop: true })
            this.tumbleweedSound.play();
        }
    }

    stopTumbleWeed(){
        this.tumbleweedMoving = false;
        this.canTumbleweed = true;
        this.tumbleweed.destroy();
        var fadeAudio = setInterval(() => {
            if(this.tumbleweedSound.volume <= 0){
                clearInterval(fadeAudio);
                this.tumbleweedSound.stop();
            }
            this.tumbleweedSound.volume -= 0.01;
        }, 200);
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

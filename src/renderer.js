window.addEventListener("DOMContentLoaded", () => {
  playMusicForCurrentPage();
});

const homePage = document.getElementById('homePage');
const weatherPage = document.getElementById('weatherPage');
const dayCityInput = document.getElementById('dayCityInput');
const nightCityInput = document.getElementById('nightCityInput');

//====================PAGE NAVIGATION=========================
document.getElementById('startBtn').addEventListener('click', () => {
  playSound("click", 0.4);
  
  homePage.classList.remove('active');
  weatherPage.classList.add('active');
  playMusicForCurrentPage();
  setDayNightByLocalTime();
});

document.getElementById('backBtn').addEventListener('click', () => {
  playSound("door", 0.4, 2);

  weatherPage.classList.remove('active');
  homePage.classList.add('active');

  playMusicForCurrentPage();

  stopWalking();
  
});

[dayCityInput, nightCityInput].forEach(input => {
  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      getWeather();
    }
  });
});


//================LIGHT/DARK MODE=================================
const themeTargets = document.querySelectorAll('.theme');

document.getElementById('bulbBtn').addEventListener('click', () => {
  playSound("lightBulb", 0.4);
  
  themeTargets.forEach(el => el.classList.toggle('dark'));

  playMusicForCurrentPage();
  
  const isDark = document.getElementById('homePage').classList.contains('dark');
  const dialogue=document.querySelector('.dialogue_');
  if (isDark) {
    dialogue.textContent = 'waiting for something to happen?';
  } else {
    dialogue.textContent = 'welcome to white space';
  }
});
//=================================================================


//=============================DAY/NIGHT UI============================
function setDayNightByLocalTime() {
  const hour = new Date().getHours();

  const isDay=hour >= 6 && hour < 18;
  applyTheme(isDay);
}

function applyTheme(isDay) {
  const dayUI = document.getElementById('dayUI');
  const nightUI = document.getElementById('nightUI');

  const dayStyle = document.getElementById('dayStyle');
  const nightStyle = document.getElementById('nightStyle');

  if (isDay) {
    dayUI.classList.add('active');
    nightUI.classList.remove('active');

    dayStyle.disabled = false;
    nightStyle.disabled = true;
  } else {
    nightUI.classList.add('active');
    dayUI.classList.remove('active');

    nightStyle.disabled = false;
    dayStyle.disabled = true;
  }
  playMusicForCurrentPage();
}


function showMessage(tempText, descText) {
  if (document.getElementById('dayUI').classList.contains('active')) {
    document.getElementById('dayTemp').textContent = tempText;
    document.getElementById('dayDesc').textContent = descText;
  } 
  else if (document.getElementById('nightUI').classList.contains('active')) {
    document.getElementById('nightTemp').textContent = tempText;
    document.getElementById('nightDesc').textContent = descText;
  }
}


//=======================TOGGLE DAY/NIGHT UI==========================
document.addEventListener('keydown', (e) => {
  if (e.key === '/') {
    const isDay = document.getElementById('dayUI').classList.contains('active');
    applyTheme(!isDay);

    stopWalking();
  }
});

//=====================WALKING ANIMATION===============================
const rally = document.querySelector('.rally');
const nightUI = document.getElementById('nightUI');
const chats = nightUI.querySelector('.group8');
const walkers = document.querySelectorAll('.walk');

rally.addEventListener('click', () => {
  playSound("footsteps", 0.4);
  rally.classList.add('walking');

  chats.classList.add('hidden');

  walkers.forEach(w => w.classList.add('walking'));
});

function stopWalking(){
  rally.classList.remove('walking');
  chats.classList.remove('hidden');
  walkers.forEach(w=>(w.classList.remove('walking')));
}
//=================================================================


//=============================SOUND SYSTEM=========================
const sounds = {
  click: new Audio("./assets/sounds/click.mp3"),
  footsteps: new Audio("./assets/sounds/walking.mp3"),
  door: new Audio("./assets/sounds/door.mp3"),
  meow: new Audio("./assets/sounds/meow.mp3"),
  lightBulb: new Audio("./assets/sounds/lightbulb.mp3"),
  omori: new Audio("./assets/sounds/omori-heal.mp3"),
  ghost: new Audio("./assets/sounds/something.mp3"),
  beep: new Audio("./assets/sounds/beep.mp3"),
  whistle: new Audio("./assets/sounds/kel.mp3"),
};

Object.values(sounds).forEach(s => s.load());

//=====================STATE==============================
let musicEnabled = true;
let sfxEnabled = true;

const overlay = document.getElementById("soundOverlay");
const musicText = document.getElementById("musicState");
const sfxText = document.getElementById("sfxState");

const knifeBtn = document.querySelector(".audioBtn");

knifeBtn.addEventListener("click", () => {
  playSound("click", 0.4);
  overlay.classList.toggle("hidden");
  
});

document.getElementById("closeSoundMenu").addEventListener("click", () => {
  overlay.classList.add("hidden");
  playSound("click", 0.4);
});

//========================TOGGLES MUSIC====================
document.getElementById("toggleMusic").addEventListener("click", () => {
  playSound("beep", 0.2);
  musicEnabled = !musicEnabled;
  musicText.textContent = musicEnabled ? "ON" : "OFF";

  if (!musicEnabled) {
    stopMusic();
  } else {
    playMusicForCurrentPage();

  }
});

//========================TOGGLES SFX====================
document.getElementById("toggleSfx").addEventListener("click", () => {
  playSound("beep", 0.2);
  sfxEnabled = !sfxEnabled;
  playSound("beep", 0.2);
  sfxText.textContent = sfxEnabled ? "ON" : "OFF";
});

//===============AUDIO HELPERS====================
let bgm = null;
let currentTrack = null;

function playMusic(name, volume = 0.15) {
  if (!musicEnabled) return;
  if (currentTrack === name) return;

  stopMusic();

  bgm = new Audio(`./assets/sounds/${name}.mp3`);
  bgm.loop = true;
  bgm.volume = volume;
  bgm.play();

  currentTrack = name;
}

function stopMusic() {
  if (bgm) {
    bgm.pause();
    bgm.currentTime = 0;
    bgm = null;
  }
  currentTrack = null;
}


function playSound(name, volume = 0.7, speed = 1) {
  if (!sfxEnabled) return;
  if (!sounds[name]) return;

  const sfx = sounds[name];
  sfx.currentTime = 0;
  sfx.volume = volume;
  sfx.playbackRate = speed;

  if (bgm) {
    bgm.volume *= 0.3;
  }

  sfx.play();

  sfx.onended = () => {
    if (bgm) {
      bgm.volume = 0.5;
    }
  };
}

function playMusicForCurrentPage() {
  if (!musicEnabled) return;

  if (homePage.classList.contains("active")) {
    const isDark = homePage.classList.contains("dark");
    playMusic(isDark ? "blackspace" : "whitespace", 0.4);
  }
  else if (dayUI.classList.contains("active")) {
    playMusic("dayy", 0.35);
  }
  else if (nightUI.classList.contains("active")) {
    playMusic("night", 0.35);
  }
}


document.querySelector('.catto').addEventListener("click", () => {
  playSound("meow", 1);
});

const omoriEl = document.querySelector('.omori');
omoriEl.addEventListener("click", () => {
  const isDarkOmori = omoriEl.classList.contains('dark');
  if (isDarkOmori) {
    playSound("ghost");
  } else {
    playSound("omori", 0.3);
  }
});

//================================================================


//=================WEATHER API DATA FETCHING N LOGIC=================
async function getWeather() {

  function getActiveCityInput() {
  if (document.getElementById('dayUI').classList.contains('active')) {
      return document.getElementById('dayCityInput');
    }
    return document.getElementById('nightCityInput');
  }


  const city = getActiveCityInput().value.trim();
  const apiKey = '3a09af1e638fcf9e07ba2b7f19674a51';
  const url = `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${apiKey}&units=metric`;

  if(!city){
    showMessage(`:O`, `pls enter a city`);
    return;
  }
  
  console.log("fetching:", url);

  try {
  const response = await fetch(url);
  const data = await response.json();
  console.log(data);

  if (data.cod != 200) {
    showMessage('um-', 'city not found');
    return;
  }

  const temp = Math.round(data.main.temp);
  const desc = data.weather[0].description;

  showMessage(`${temp}°C`, `It's ${desc}!`);
  }
  catch (error) {
    console.error(error);
    showMessage('--', 'something went wrong');
  }
}
//==================================================================
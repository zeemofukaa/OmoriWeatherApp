window.addEventListener("DOMContentLoaded", () => {
  playMusic("whiteSpace");
});

const homePage = document.getElementById('homePage');
const weatherPage = document.getElementById('weatherPage');



document.getElementById('startBtn').addEventListener('click', () => {
  playSound("click", 0.4);
  
  homePage.classList.remove('active');
  weatherPage.classList.add('active');

  setDayNightByLocalTime();
});

document.getElementById('backBtn').addEventListener('click', () => {
  playSound("door", 0.4, 2);
  const isDark = document.getElementById('homePage').classList.contains('dark');
  if(isDark){
    playMusic("blackspace", 0.4);
  }
  else{
    playMusic("whitespace");
  }

  weatherPage.classList.remove('active');
  homePage.classList.add('active');

  rally.classList.remove('walking');
  chats.classList.remove('hidden');
  walkers.forEach(w=>(w.classList.remove('walking')));

});


const dayCityInput = document.getElementById('dayCityInput');
const nightCityInput = document.getElementById('nightCityInput');

[dayCityInput, nightCityInput].forEach(input => {
  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      getWeather();
    }
  });
});


// document.querySelectorAll('.hand').forEach(hand => {
//   setTimeout(() => {
//     hand.style.animation = 'none';
//   }, 5000);
// });


//LIGHT/DARK MODE
const themeTargets = document.querySelectorAll('.theme');

document.getElementById('bulbBtn').addEventListener('click', () => {
  playSound("lightBulb", 0.4);
  themeTargets.forEach(el => el.classList.toggle('dark'));

  const isDark = document.getElementById('homePage').classList.contains('dark');
  const dialogue=document.querySelector('.dialogue_');
  if (isDark) {
    playMusic("blackspace", 0.4);
    dialogue.textContent = 'waiting for something to happen?';
  } else {
    playMusic("whitespace");
    dialogue.textContent = 'welcome to white space';
  }
});
//------------------------------------------------------------


//DAY/NIGHT UI
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
    playMusic("dayy", 0.4);
    dayUI.classList.add('active');
    nightUI.classList.remove('active');

    dayStyle.disabled = false;
    nightStyle.disabled = true;
  } else {
    playMusic("night", 0.4);
    nightUI.classList.add('active');
    dayUI.classList.remove('active');

    nightStyle.disabled = false;
    dayStyle.disabled = true;
  }
}



//WEATHER API DATA FETCHING N LOGIC
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
// ---------------------------------------------------------------------

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

document.addEventListener('keydown', (e) => {
  if (e.key === '/') {
    const isDay = document.getElementById('dayUI').classList.contains('active');
    applyTheme(!isDay);
  }
});


//walking animation
const rally = document.querySelector('.rally');
const nightUI = document.getElementById('nightUI');
const chats = nightUI.querySelector('.group8');
const walkers = document.querySelectorAll('.walk');

rally.addEventListener('click', () => {
  playSound("footstep", 0.4);
  rally.classList.add('walking');

  chats.classList.add('hidden');

  walkers.forEach(w => w.classList.add('walking'));
});


const sounds = {
  click: new Audio("./assets/sounds/click.mp3"),
  footstep: new Audio("./assets/sounds/walking.mp3"),
  door: new Audio("./assets/sounds/door.mp3"),
  meow: new Audio("./assets/sounds/meow.mp3"),
  lightBulb: new Audio("./assets/sounds/lightbulb.mp3"),
  omori: new Audio("./assets/sounds/omori-heal.mp3"),
  //glitch: new Audio("./assets/sounds/glitch.mp3"),
};

// Prevent lag on first play
Object.values(sounds).forEach(s => s.load());

function playSound(name, volume = 0.7, speed=1) {
  if (!sounds[name]) return;
  sounds[name].currentTime = 0;
  sounds[name].volume = volume;
  sounds[name].playbackRate = speed;

  if (currentMusic) {
    currentMusic.volume *= 0.3; // reduce to 30%
  }
  sounds[name].play();
  sounds[name].onended = () => {
    if (currentMusic) {
      currentMusic.volume = 0.5; // your normal music volume
    }
  };
}
let currentMusic = null;
function playMusic(name, volume = 0.2, speed = 1) {
  // Stop old music
  if (currentMusic) {
    currentMusic.pause();
    currentMusic.currentTime = 0;
  }

  const audio = new Audio(`./assets/sounds/${name}.mp3`);
  audio.volume = volume;
  audio.playbackRate = speed;
  audio.loop = true;
  audio.play();

  currentMusic = audio;
}

document.querySelector('.catto').addEventListener("click", () => {
  playSound("meow", 0.6);
});
document.querySelector('.omori').addEventListener("click", () => {
  playSound("omori", 0.3);
});
document.querySelector('.basil').addEventListener("click", () => {
  document.querySelector('.truth').classList.add("active");
});


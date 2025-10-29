// custom.js - JavaScript personalizzato per Word Predictor

$(document).ready(function() {
  
  // ===== SET DEFAULT CLASSIC THEME =====
  $('body').addClass('classic-theme');
  
  // ===== CYBER BUTTON EFFECTS =====
  $('.btn-primary').hover(
    function() {
      $(this).css('box-shadow', '0 0 30px rgba(0, 255, 136, 0.8)');
    },
    function() {
      $(this).css('box-shadow', '0 0 20px rgba(0, 255, 136, 0.4)');
    }
  );
  
  // ===== CYBER PREDICT BUTTON =====
  $('#predict_btn').click(function() {
    var originalText = $(this).html();
    $(this).html('🔄 PROCESSING...');
    $(this).prop('disabled', true);
    $(this).css('background', 'linear-gradient(45deg, #00d4ff, #ff0080)');
    
    setTimeout(function() {
      $('#predict_btn').html(originalText);
      $('#predict_btn').prop('disabled', false);
      $('#predict_btn').css('background', 'linear-gradient(45deg, #00ff88, #00d4ff)');
    }, 2000);
  });
  

  
  // ===== TOOLTIP INFORMATIVI =====
  $('[data-toggle="tooltip"]').tooltip();
  
  // ===== CONTATORE CARATTERI INPUT =====
  $('#input_text').on('input', function() {
    var text = $(this).val();
    var wordCount = text.trim().split(/\s+/).length;
    if (text.trim() === '') wordCount = 0;
    
    // Aggiorna contatore se esiste
    if ($('#word-counter').length) {
      $('#word-counter').text(wordCount + ' words');
    }
  });
  
  // ===== ANIMAZIONE SMOOTH SCROLL =====
  $('a[href^="#"]').on('click', function(event) {
    var target = $(this.getAttribute('href'));
    if (target.length) {
      event.preventDefault();
      $('html, body').stop().animate({
        scrollTop: target.offset().top - 80
      }, 1000);
    }
  });
  
  // ===== FEEDBACK VISIVO PER LE PREDIZIONI =====
  function showPredictionFeedback(timing) {
    var feedbackClass = '';
    var message = '';
    
    if (timing < 50) {
      feedbackClass = 'status-fast';
      message = '🚀 Lightning Fast!';
    } else if (timing < 200) {
      feedbackClass = 'status-good';
      message = '✅ Good Speed!';
    } else {
      feedbackClass = 'status-slow';
      message = '⏱️ Processing...';
    }
    
    // Crea notification temporanea
    $('body').append(
      '<div class="prediction-notification ' + feedbackClass + '" style="position: fixed; top: 20px; right: 20px; z-index: 1000; opacity: 0;">' +
      message +
      '</div>'
    );
    
    // Anima la notifica
    $('.prediction-notification').animate({opacity: 1}, 300).delay(2000).animate({opacity: 0}, 300, function() {
      $(this).remove();
    });
  }
  
  // ===== EASTER EGG - KONAMI CODE =====
  var konamiCode = [38, 38, 40, 40, 37, 39, 37, 39, 66, 65];
  var konamiIndex = 0;
  var rainbowTimer = null;
  
  $(document).keydown(function(e) {
    if (e.keyCode === konamiCode[konamiIndex]) {
      konamiIndex++;
      if (konamiIndex === konamiCode.length) {
        // Easter egg attivato!
        activateRainbowMode();
        konamiIndex = 0;
      }
    } else {
      konamiIndex = 0;
    }
  });
  
  function activateRainbowMode() {
    // Clear any existing timer
    if (rainbowTimer) clearTimeout(rainbowTimer);
    
    // Activate rainbow mode
    $('body').addClass('rainbow-mode');
    
    // Show spectacular notification
    showRainbowNotification();
    
    // Auto-disable after 6 seconds
    rainbowTimer = setTimeout(function() {
      $('body').removeClass('rainbow-mode');
      showThemeNotification('🌈 Rainbow Mode Deactivated');
    }, 6000);
  }
  
  function showRainbowNotification() {
    // Remove existing notifications
    $('.rainbow-notification').remove();
    
    // Create rainbow notification with special styling
    $('body').append(
      '<div class="rainbow-notification" style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); ' +
      'z-index: 1002; opacity: 0; background: linear-gradient(45deg, #ff6b6b, #4ecdc4, #45b7d1, #96ceb4, #ffa726); ' +
      'background-size: 300% 300%; animation: rainbow-bg 2s ease infinite; color: white; padding: 30px 40px; ' +
      'border-radius: 15px; font-weight: bold; font-size: 1.5em; text-align: center; ' +
      'box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3); border: 3px solid white;">' +
      '<div style="font-size: 2em; margin-bottom: 10px;">🎉🌈✨</div>' +
      '<div>EASTER EGG UNLOCKED!</div>' +
      '<div style="font-size: 0.8em; margin-top: 10px; opacity: 0.9;">Rainbow Mode Activated!</div>' +
      '</div>'
    );
    
    // Animate the notification
    $('.rainbow-notification').animate({opacity: 1}, 500).delay(3000).animate({opacity: 0}, 500, function() {
      $(this).remove();
    });
  }
  
  // ===== THEME TOGGLE (CYBERPUNK ↔ CLASSIC) =====
  if ($('#dark-mode-toggle').length) {
    $('#dark-mode-toggle').click(function() {
      $('body').toggleClass('classic-theme');
      var isClassic = $('body').hasClass('classic-theme');
      
      // Aggiorna il testo del bottone
      $(this).html(isClassic ? '🌌 Cyber Mode' : '🌙 Classic Mode');
      
      // Animazione smooth di transizione
      $('body').css('transition', 'all 0.5s ease');
      
      // Feedback visivo
      var message = isClassic ? '🏛️ Classic Bootstrap Theme Active!' : '🌌 Cyberpunk Theme Active!';
      showThemeNotification(message);
      
      // Remove transition after animation
      setTimeout(function() {
        $('body').css('transition', '');
      }, 500);
    });
  }
  
  // ===== THEME NOTIFICATION =====
  function showThemeNotification(message) {
    // Remove existing notifications
    $('.theme-notification').remove();
    
    // Crea notification
    $('body').append(
      '<div class="theme-notification" style="position: fixed; top: 70px; right: 20px; z-index: 1001; opacity: 0; ' +
      'background: linear-gradient(45deg, #007bff, #0056b3); color: white; padding: 15px 25px; ' +
      'border-radius: 8px; font-weight: bold; box-shadow: 0 4px 15px rgba(0, 123, 255, 0.3);">' +
      message +
      '</div>'
    );
    
    // Anima la notifica
    $('.theme-notification').animate({opacity: 1}, 300).delay(2500).animate({opacity: 0}, 300, function() {
      $(this).remove();
    });
  }
  
});

// ===== CSS RAINBOW MODE =====
$('<style>').prop('type', 'text/css').html(`
  .rainbow-mode {
    animation: rainbow-bg 3s ease infinite;
  }
  
  @keyframes rainbow-bg {
    0% { background: linear-gradient(45deg, #ff6b6b, #4ecdc4); }
    25% { background: linear-gradient(45deg, #4ecdc4, #45b7d1); }
    50% { background: linear-gradient(45deg, #45b7d1, #96ceb4); }
    75% { background: linear-gradient(45deg, #96ceb4, #ffa726); }
    100% { background: linear-gradient(45deg, #ffa726, #ff6b6b); }
  }
`).appendTo('head');
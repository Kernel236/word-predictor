// custom.js - JavaScript personalizzato per Word Predictor

$(document).ready(function() {
  
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
  
  $(document).keydown(function(e) {
    if (e.keyCode === konamiCode[konamiIndex]) {
      konamiIndex++;
      if (konamiIndex === konamiCode.length) {
        // Easter egg attivato!
        $('body').addClass('rainbow-mode');
        alert('🎉 Easter Egg Unlocked! Rainbow Mode Activated!');
        konamiIndex = 0;
      }
    } else {
      konamiIndex = 0;
    }
  });
  
  // ===== DARK MODE TOGGLE (BONUS) =====
  if ($('#dark-mode-toggle').length) {
    $('#dark-mode-toggle').click(function() {
      $('body').toggleClass('dark-mode');
      var isDark = $('body').hasClass('dark-mode');
      $(this).text(isDark ? '☀️ Light Mode' : '🌙 Dark Mode');
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
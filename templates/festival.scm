;; WARNING: It is inherently insecure to run a festival instance as a
;; server, mainly because it exposes the whole system to exploits which
;; can be easily used by attackers to gain access to your
;; computer. This is because of the inherent design of the festival
;; server. Please use it only in a situation where you are sure that
;; you will not be subjected to such an attack, or have adequate
;; security precautions.

;; This file has been provided as an example file for your use, should
;; you wish to run festival as a server.

; Maximum number of clients on the server
;(set! server_max_clients 10)

; Server port
;(set! server_port 1314)

; Server password:
;(set! server_passwd "${SECRET_FESTIVAL_PASSWORD}")

; Log file location
;(set! server_log_file "/var/log/festival/festival.log")

; Server access list (hosts)
; Example:
; (set! server_access_list '("[^.]+" "127.0.0.1" "localhost.*" "192.168.*"))
; Secure default:
;(set! server_access_list '("[^.]+" "127.0.0.1" "localhost"))

; Server deny list (hosts)

;; Debian-specific: Use aplay to play audio
(Parameter.set 'Audio_Command "aplay -q -c 1 -t raw -f s16 -r $SR $FILE")
(Parameter.set 'Audio_Method 'Audio_Command)

;;; Command for Asterisk begin

(define (tts_textasterisk string mode)
"(tts_textasterisk STRING MODE)
Apply tts to STRING. This function is specifically designed for
use in server mode so a single function call may synthesize the string.
This function name may be added to the server safe functions."
(let ((wholeutt (utt.synth (eval (list 'Utterance 'Text string)))))
(utt.wave.resample wholeutt 8000)
(utt.wave.rescale wholeutt 5)
(utt.send.wave.client wholeutt)))


;;; Command for Asterisk end
 
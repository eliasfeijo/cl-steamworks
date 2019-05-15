#|
 This file is a part of cl-steamworks
 (c) 2019 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.steamworks)

(defclass steamgameserver (interface)
  ((stats-handle :initarg :stats-handle :reader stats-handle)))

(defmethod initialize-instance :after ((interface steamgameserver) &key version stats-version steamworks)
  (setf (handle interface) (get-interface-handle* steamworks 'steam::client-get-isteam-game-server
                                                  (t-or version steam::steamgameserver-interface-version)))
  (setf (stats-handle interface) (get-interface-handle* steamworks 'steam::client-get-isteam-game-server-stats
                                                        (t-or version steam::steamgameserverstats-interface-version))))

;; FIXME: token mechanism
;; FIXME: crawl constants

(define-interface-method steamgameserver logged-on-p (steam::game-server-blogged-on))
(define-interface-method steamgameserver secure-p (steam::game-server-bsecure))
(define-interface-method steamgameserver heartbeat (steam::game-server-force-heartbeat))
(define-interface-method steamgameserver public-ip (steam::game-server-get-public-ip)
  (int->ipv4 result))
(define-interface-method steamgameserver steam-id (steam::game-server-get-steam-id))
(define-interface-method steamgameserver logoff (steam::game-server-log-off))
(define-interface-method steamgameserver (setf bot-count) ((count integer) steam::game-server-set-bot-player-count))
(define-interface-method steamgameserver (setf max-player-count) ((count integer) steam::game-server-set-max-player-count))
(define-interface-method steamgameserver (setf password-protected) (protected steam::game-server-set-password-protected))
(define-interface-method steamgameserver (setf region) ((region string) steam::game-server-set-region))
(define-interface-method steamgameserver (setf spectator-port) ((port integer) steam::game-server-set-spectator-port))
(define-interface-method steamgameserver was-restart-requested (steam::game-server-was-restart-requested))

(defmethod logon ((gameserver steamgameserver) &key token dedicated)
  (steam::game-server-set-dedicated-server (handle gameserver) dedicated)
  (if token
      (steam::game-server-log-on (handle gameserver) token)
      (steam::game-server-log-on-anonymous (handle gameserver))))

(defmethod (setf key-value) ((value string) (gameserver steamgameserver) (key string))
  (steam::game-server-set-key-value (handle gameserver) key value)
  value)

(defmethod (setf key-value) ((value null) (gameserver steamgameserver) (key (eql T)))
  (steam::game-server-clear-all-key-values (handle gameserver))
  value)

(defmethod associate-with-clan ((clan clan) (gameserver steamgameserver))
  (with-call-result (result :poll T) (steam::game-server-associate-with-clan (handle gameserver) (handle clan))
    (with-error-on-failure (steam::associate-with-clan-result result))))

(defmethod compute-player-compatibility ((user friend) (gameserver steamgameserver))
  (with-call-result (result :poll T) (steam::game-server-compute-new-player-compatibility (handle gameserver) (steam-id user))
    (with-error-on-failure (steam::associate-with-clan-result result))))

(defmethod next-outgoing-packet ((gameserver steamgameserver))
  (cffi:with-foreign-objects ((buffer :uint8 (* 16 1024))
                              (ip :uint32)
                              (port :uint16))
    (let ((size (steam::game-server-get-next-outgoing-packet (handle gameserver) buffer (* 16 1024) ip port)))
      (values (cffi:foreign-array-to-lisp buffer (list :array :uint8 size) :element-type '(unsigned-byte 8))
              (int->ipv4 (cffi:mem-ref ip :uint32))
              (cffi:mem-ref port :uint16)))))

(defmethod handle-incoming-packet ((gameserver steamgameserver) packet ip port)
  (cffi:with-foreign-array (data packet :uint8)
    (steam::game-server-handle-incoming-packet (handle gameserver) data (length packet) (ipv4->int ip) port)))

(defmethod request-user-group-status ((user friend) (group friend-group) (gameserver steamgameserver))
  (steam::game-server-request-user-group-status (handle gameserver) (handle user) (handle group)))

(defmethod (setf game-data) ((value string) (gameserver steamgameserver))
  (check-utf8-size 2048 value)
  (steam::game-server-set-game-data (handle gameserver) value)
  value)

(defmethod (setf game-data) ((value cons) (gameserver steamgameserver))
  (setf (game-data gameserver) (format NIL "~{~a~^,~}" value)))

(defmethod (setf game-description) ((value string) (gameserver steamgameserver))
  (check-utf8-size 64 value)
  (steam::game-server-set-game-description (handle gameserver) value)
  value)

(defmethod (setf game-tags) ((value string) (gameserver steamgameserver))
  (check-utf8-size 128 value)
  (steam::game-server-set-game-tags (handle gameserver) value)
  value)

(defmethod (setf game-tags) ((value cons) (gameserver steamgameserver))
  (setf (game-tags gameserver) (format NIL "~{~a~^,~}" value)))

(defmethod (setf map-name) ((value string) (gameserver steamgameserver))
  (check-utf8-size 32 value)
  (steam::game-server-set-map-name (handle gameserver) value)
  value)

(defmethod (setf heartbeat) ((value T) (gameserver steamgameserver))
  (steam::game-server-enable-heartbeats (handle gameserver) T))

(defmethod (setf heartbeat) ((value null) (gameserver steamgameserver))
  (steam::game-server-enable-heartbeats (handle gameserver) NIL))

(defmethod (setf heartbeat) ((value number) (gameserver steamgameserver))
  (if (= 0 value)
      (setf (heartbeat gameserver) NIL)
      (steam::game-server-set-heartbeat-interval (handle gameserver) (millisecs value))))

(defmethod (setf product) ((value integer) (gameserver steamgameserver))
  (steam::game-server-set-product (handle gameserver) (princ-to-string value)))

(defmethod (setf product) ((value app) (gameserver steamgameserver))
  (setf (product gameserver) (app-id value)))

(defmethod (setf product) ((value (eql T)) (gameserver steamgameserver))
  (setf (product gameserver) (app (interface 'steamapps gameserver))))

(defmethod (setf spectator-port) ((value null) (gameserver steamgameserver))
  (setf (spectator-port gameserver) 0))

(defmethod (setf spectator-server) ((value string) (gameserver steamgameserver))
  (check-utf8-size 32 value)
  (steam::game-server-set-spectator-server-name (handle gameserver) value)
  value)

(defmethod user-stats ((user friend) (gameserver steamgameserver) &key stats achievements)
  (with-call-result (result :poll T) (steam::game-server-stats-request-user-stats (stats-handle gameserver) (steam-id user))
    (with-error-on-failure (steam::gsstats-received-result result))
    (list :stats
          (cffi:with-foreign-object (data :int32)
            (loop for stat in stats
                  collect (destructuring-bind (name type) (enlist stat :int32)
                            (check-utf8-size 128 name)
                            (ecase type
                              (:int32
                               (unless (steam::game-server-stats-get-user-stat (stats-handle gameserver) (steam-id user) name data)
                                 (error "FIXME: No such user stat"))
                               (cons name (cffi:mem-ref data :int32)))
                              (:float
                               (unless (steam::game-server-stats-get-user-stat0 (stats-handle gameserver) (steam-id user) name data)
                                 (error "FIXME: No such user stat"))
                               (cons name (cffi:mem-ref data :float)))))))
          :achievements
          (cffi:with-foreign-object (data :bool)
            (loop for achievement in achievements
                  do (unless (steam::game-server-stats-get-user-achievement (stats-handle gameserver) (steam-id user) achievement data)
                       (error "FIXME: No such achievement"))
                  collect (cons achievement (cffi:mem-ref data :bool)))))))

(defmethod (setf user-stats) ((value cons) (user friend) (gameserver steamgameserver) &key sync)
  (with-call-result (result :poll T)  (steam::game-server-stats-request-user-stats (stats-handle gameserver) (steam-id user))
    (with-error-on-failure (steam::gsstats-received-result result))
    (destructuring-bind (&key stats achievements avgrates) value
      (loop for (stat . value) in stats
            do (unless (etypecase value
                         (integer
                          (steam::game-server-stats-set-user-stat (stats-handle gameserver) (steam-id user) stat value))
                         (float
                          (steam::game-server-stats-set-user-stat0 (stats-handle gameserver) (steam-id user) stat (coerce value 'single-float))))
                 (error "FIXME: No such user stat")))
      (loop for (achievement . value) in achievements
            do (unless (if value
                           (steam::game-server-stats-set-user-achievement (stats-handle gameserver) (steam-id user) achievement)
                           (steam::game-server-stats-clear-user-achievement (stats-handle gameserver) (steam-id user) achievement))
                 (error "FIXME: No such achievement")))
      (loop for (avgrate count length) in avgrates
            do (unless (steam::game-server-stats-update-user-avg-rate-stat (stats-handle gameserver) (steam-id user) avgrate count length)
                 (error "FIXME: No such avgrate")))))
  (when sync
    (loop for i from 0 below 10
          do (with-call-result (result :poll T) (steam::game-server-stats-store-user-stats (stats-handle gameserver) (steam-id user))
               (when (eq :ok (steam::gsstats-stored-result result))
                 (return)))
             (sleep 0.1)
          finally (error "FIXME: failed to store results after 10 retries.")))
  value)
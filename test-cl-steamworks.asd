#|
 This file is a part of cl-steamworks
 (c) 2019 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(asdf:defsystem test-cl-steamworks
    :version "1.0.0"
    :license "Artistic"
    :author "Nicolas Hafner <shinmera@tymoon.eu>"
    :maintainer "Nicolas Hafner <shinmera@tymoon.eu>"
    :description "Test system for cl-steamworks API."
    :homepage "https://github.com/Shinmera/cl-steamworks"
    :depends-on (:cl-steamworks
                 :parachute)
    :serial T
    :pathname "test/"
    :components ((:file "package")))

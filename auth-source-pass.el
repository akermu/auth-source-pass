;;; auth-source-pass.el --- Connect auth-source and pass

;; Copyright (C) 2016 by Lukas Fürmetz
;; URL: http://github.com/akermu/auth-source-pass
;; Package-Requires: ((cl-lib "0.5"))
;; Version: 0.1
;; Keywords: auth-source pass

;; auth-source-pass is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option) any
;; later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;

;; Installation:

;;  Put auth-source-pass.el in your `load-path' and require and enable it:

;;  (require 'auth-source-pass)
;;  (auth-source-pass-enable)

;; Usage:

;;  This requires a metadata file in the password-store named ".metadata.gpg".
;;  Lines beginning with a # are ignored. The content of the files are
;;  structured as followed:

;;  # url user pass
;;  example.org username pathOfPassword
;;  example.net username2 pathOfPassword

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'auth-source)

(defvar auth-source-pass-cache nil)

(cl-defun auth-source-pass-search (&rest spec
                                &key backend type host user port
                                &allow-other-keys)
  "Given a property list SPEC, return search matches from the :backend.
See `auth-source-search' for details on SPEC."
  (unless auth-source-pass-cache
    (auth-source-pass-load-metadata))
  (when (listp host)
    (setq host (car host)))
  (when-let ((item (car (cl-remove-if-not (lambda (elem)
                                            (string-match (car elem) host))
                                          auth-source-pass-cache))))
    `((:host ,(nth 0 item) :user ,(nth 1 item) :secret ,(auth-source-pass-get-secret (nth 2 item))))))

(defun auth-source-pass-get-secret (name)
  (when-let ((pass (process-lines "pass" "show" name)))
    (car pass)))

(defun auth-source-pass-reload-metadata ()
  (interactive)
  (setq auth-source-pass-cache nil)
  (auth-source-pass-load-metadata))

(defun auth-source-pass-load-metadata ()
  (let ((lines (process-lines "pass" "show" ".metadata")))
    (dolist (line lines)
      (unless (string-match "\w*#" line)
        (when (string-match "^\\(.*?\\)[ ]\\(.*?\\)[ ]\\(.*?\\)$" line)
          (push `(,(match-string 1 line)
                  ,(match-string 2 line)
                  ,(match-string 3 line))
                auth-source-pass-cache ))))))

(defvar auth-source-pass-backend
  (auth-source-backend :source ""
                       :type 'auth-source-pass
                       :search-function #'auth-source-pass-search)
  "Auth-source backend for pass.")

;;;###autoload
(defun auth-source-pass-enable ()
  (interactive)
  (add-to-list 'auth-sources 'auth-source-pass))


(defun auth-source-pass-backend-parse (entry)
  "Create a auth-source-pass backend from ENTRY."
  (when (eq entry 'auth-source-pass)
    (auth-source-backend-parse-parameters entry auth-source-pass-backend)))

(advice-add 'auth-source-backend-parse :before-until #'auth-source-pass-backend-parse)

(provide 'auth-source-pass)

;;; auth-source-pass.el ends here

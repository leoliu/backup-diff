;;; backup-diff.el --- backup-diff command           -*- lexical-binding: t; -*-

;; Copyright (C) 2013  Leo Liu

;; Author: Leo Liu <sdl.web@gmail.com>
;; Version: 1.0
;; Keywords: tools, data
;; Created: 2013-09-21

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Command `backup-diff' is like `diff-backup' but allows moving
;; between backup files easily.

;;; Code:

(require 'diff)

(defun backup-files (file)
  "Get a list of all backup files of FILE (included)."
  (let* ((backup (file-name-sans-versions (make-backup-file-name file)))
         (bfile (file-name-nondirectory backup))
         (dir (file-name-directory backup))
         (re (concat (regexp-quote bfile) file-name-version-regexp "\\'"))
         (files (cons file (directory-files dir t re 'nosort))))
    (sort files #'file-newer-than-file-p)))

(defvar-local backup-files nil)
(put 'backup-files 'permanent-local t)

(defvar-local backup-file-pointer nil)
(put 'backup-file-pointer 'permanent-local t)

;;;###autoload
(defun backup-diff (file &optional switches)
  "Diff FILE with its backup files."
  (interactive (list (read-file-name "Diff (file with backup): ")
		     (diff-switches)))
  (let ((files (backup-files file)))
    (or (cdr files) (error "No backup found for %s" file))
    (pop-to-buffer (diff-no-select (cadr files) (car files) switches))
    (setq backup-files files)
    (setq backup-file-pointer 1)
    (backup-diff-mode +1)))

(defun backup-diff-file-next (count)
  (interactive "p")
  (let ((pointer (if (> count 0)
                     (min (+ count backup-file-pointer)
                          (1- (length backup-files)))
                   (max 1 (+ count backup-file-pointer)))))
    (when (= pointer backup-file-pointer)
      (error "No %s backup file" (if (> count 0) "next" "prev")))
    (setq backup-file-pointer pointer)
    (diff-no-select (nth backup-file-pointer backup-files)
                    (car backup-files)
                    diff-switches)))

(defun backup-diff-file-prev (count)
  (interactive "p")
  (backup-diff-file-next (- count)))

(defvar backup-diff-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap diff-file-prev] #'backup-diff-file-prev)
    (define-key map [remap diff-file-next] #'backup-diff-file-next)
    map))

;; Need permanent-local because `diff-no-select' calls diff-mode
;; unconditionally.
(put 'backup-diff-mode 'permanent-local t)
(define-minor-mode backup-diff-mode nil :lighter " BackUp")

(provide 'backup-diff)
;;; backup-diff.el ends here

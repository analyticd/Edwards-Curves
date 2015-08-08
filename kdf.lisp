;; kdf.lisp -- Key Derivation Function
;;
;; -----------------------------------------------

(in-package :ecc-crypto-b571)

;; ------------------------------------------------------------------------

(defun mask-off (arr rembits)
  (when (plusp rembits)
    (setf (aref arr 0) (ldb (byte rembits 0) (aref arr 0))))
  arr)


(defun apply-c-kdf (nbits keys)
  (apply 'c-kdf nbits keys))

(defun kdf (nbits &rest keys)
  (with-fast-impl
   (apply-c-kdf nbits keys)
   (let* ((nbytes (ceiling nbits 8))
          (ans    (make-ub-array nbytes
                                 :initial-element 0))
          (ctr    0)
          (keys   (mapcar #'ensure-8bitv keys))
          (dig    (ironclad:make-digest :sha256))
          (hash   (make-ub-array 32
                                 :initial-element 0))
          (rembits (rem nbits 8)))
     (labels ((gen-partial (start end)
                (incf ctr)
                (let ((num (ensure-8bitv
                            (convert-int-to-nbytes ctr 4))))
                  (loop repeat 8192 do
                        (reinitialize-instance dig)
                        (apply #'safe-update-digest dig num hash keys)
                        (ironclad:produce-digest dig :digest hash))
                  (replace ans hash :start1 start :end1 end) )))
       
       (loop for start from 0 below nbytes by 32 do
             (let ((nb (min 32 (- nbytes start))))
               (gen-partial start (+ start nb))))
       (mask-off ans rembits) ))))



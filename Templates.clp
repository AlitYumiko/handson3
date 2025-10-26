;; ------------------------------------------------
;; Templates Recomender System
;; ------------------------------------------------

;; --- PRODUCTOS ---
(deftemplate smartphone
   (slot sku (type STRING))
   (slot marca (type SYMBOL))
   (slot modelo (type STRING))
   (slot color (type SYMBOL))
   (slot precio (type FLOAT))
   (slot stock (type INTEGER))
)
(deftemplate computador
   (slot sku (type STRING))
   (slot marca (type SYMBOL))
   (slot modelo (type STRING))
   (slot color (type SYMBOL))
   (slot precio (type FLOAT))
   (slot stock (type INTEGER))
)
(deftemplate accesorio
   (slot sku (type STRING))
   (slot tipo (type STRING))
   (slot marca (type SYMBOL))
   (slot precio (type FLOAT))
   (slot stock (type INTEGER))
)

;; --- CLIENTES Y PAGOS ---
(deftemplate cliente
   (slot cliente-id (type INTEGER))
   (multislot nombre (type STRING))
   (slot nivel (type SYMBOL) (default bronce))
)
(deftemplate tarjeta-credito
   (slot tdc-id (type STRING))
   (slot cliente-id (type INTEGER))
   (slot banco (type SYMBOL))
   (slot grupo (type SYMBOL))
   (slot exp-date (type STRING))
)
(deftemplate vale
   (slot vale-id (type STRING))
   (slot cliente-id (type INTEGER))
   (slot monto (type FLOAT))
   (slot estado (type SYMBOL) (default activo))
)

;; --- TRANSACCIONES ---
(deftemplate orden-compra
   (slot orden-id (type INTEGER))
   (slot cliente-id (type INTEGER))
   (slot tipo-pago (type SYMBOL))
   (slot tdc-id (type STRING) (default ?NONE)) 
   (slot total (type FLOAT) (default 0.0))
   (slot estado (type SYMBOL) (default procesando))
   ;; --- INICIO DE CORRECCIÓN ---
   (slot descuento-oro-aplicado (type SYMBOL) (default no))
   (slot promo-envio-aplicada (type SYMBOL) (default no))
   ;; --- FIN DE CORRECCIÓN ---
)
(deftemplate linea-item
   (slot order-id (type INTEGER))
   (slot sku (type STRING))
   (slot cantidad (type INTEGER))
   (slot precio-unitario (type FLOAT))
)

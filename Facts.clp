;; ------------------------------------------------
;; Hechos Recomender System (Inventario y Clientes)
;; ------------------------------------------------

(deffacts inventario-y-clientes
   
   ;; --- Smartphones (Stock inicial) ---
   (smartphone (sku "APL-IP16-R") (marca apple) (modelo "iPhone16") (color rojo) (precio 27000.0) (stock 50))
   (smartphone (sku "APL-IP15-A") (marca apple) (modelo "iPhone15") (color azul) (precio 22000.0) (stock 40))
   (smartphone (sku "SAM-N21-N") (marca samsung) (modelo "Note 21") (color negro) (precio 24000.0) (stock 30))
   (smartphone (sku "GOO-PIX9-B") (marca google) (modelo "Pixel 9") (color blanco) (precio 21000.0) (stock 25))

   ;; --- Computadoras (Stock inicial) ---
   (computador (sku "APL-MBA-G") (marca apple) (modelo "MacBook Air") (color gris) (precio 35000.0) (stock 20))
   (computador (sku "APL-MBP-G") (marca apple) (modelo "macbookpro") (color gris) (precio 47000.0) (stock 15))
   (computador (sku "DEL-XPS-N") (marca dell) (modelo "XPS 15") (color negro) (precio 42000.0) (stock 30))

   ;; --- Accesorios (Stock inicial) ---
   (accesorio (sku "ACC-FUN-IP16") (tipo "funda") (marca apple) (precio 1200.0) (stock 100)) ;; 
   (accesorio (sku "ACC-MIC-IP16") (tipo "mica") (marca generico) (precio 800.0) (stock 100)) ;; 
   (accesorio (sku "ACC-HUB-C") (tipo "hub usb-c") (marca generico) (precio 900.0) (stock 200)) ;
   (accesorio (sku "ACC-CAR-APL") (tipo "cargador") (marca apple) (precio 1000.0) (stock 80)) ;; 
   ;; --- Clientes Registrados ---
   (cliente (cliente-id 1) (nombre Juan Perez) (nivel oro))
   (cliente (cliente-id 2) (nombre Maria Lopez) (nivel plata))
   (cliente (cliente-id 3) (nombre Carlos Ruiz) (nivel bronce))

   ;; --- Tarjetas de Clientes ---
   (tarjeta-credito (tdc-id "TDC-1A") (cliente-id 1) (banco banamex) (grupo visa) (exp-date "12-25"))
   (tarjeta-credito (tdc-id "TDC-1B") (cliente-id 1) (banco liverpool) (grupo visa) (exp-date "06-26"))
   (tarjeta-credito (tdc-id "TDC-2A") (cliente-id 2) (banco bbva) (grupo mastercard) (exp-date "03-27"))
   (tarjeta-credito (tdc-id "TDC-3A") (cliente-id 3) (banco santander) (grupo visa) (exp-date "11-24"))
)